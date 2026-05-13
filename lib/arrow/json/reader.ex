defmodule Arrow.Json.Reader do
  @moduledoc """
  Parses Arrow integration test JSON into the in-memory data model.

  The JSON form is canonical: every value is a `0`/`1` int (validity), a number,
  or a string. Integer-typed columns that don't fit in a JSON number losslessly
  (Int64, UInt64, Date64, Timestamp) are encoded as decimal strings — this
  reader accepts both. Binary columns are hex-encoded strings.
  """

  alias Arrow.{Array, Buffer, Field, RecordBatch, Schema, Type}

  @doc """
  Parses a decoded JSON map into `{:ok, %{schema:, batches:}}` or
  `{:error, reason}`.
  """
  @spec read(map()) :: {:ok, %{schema: Schema.t(), batches: [RecordBatch.t()]}} | {:error, term()}
  def read(%{"schema" => schema_map} = doc) do
    schema = read_schema(schema_map)
    batches = doc |> Map.get("batches", []) |> Enum.map(&read_batch(&1, schema))
    {:ok, %{schema: schema, batches: batches}}
  rescue
    e -> {:error, e}
  end

  def read(_), do: {:error, :missing_schema}

  ## ---------------------------------------------------------------------
  ## Schema
  ## ---------------------------------------------------------------------

  defp read_schema(%{"fields" => fields} = map) do
    %Schema{
      fields: Enum.map(fields, &read_field/1),
      metadata: read_metadata(map["metadata"])
    }
  end

  defp read_field(%{"name" => name, "type" => type_map} = map) do
    if Map.has_key?(map, "dictionary") do
      raise ArgumentError, "unsupported type: dictionary-encoded field #{inspect(name)}"
    end

    %Field{
      name: name,
      type: read_type(type_map),
      nullable: Map.get(map, "nullable", true),
      children: map |> Map.get("children", []) |> Enum.map(&read_field/1),
      metadata: read_metadata(map["metadata"])
    }
  end

  defp read_metadata(nil), do: %{}
  defp read_metadata([]), do: %{}

  defp read_metadata(list) when is_list(list) do
    Map.new(list, fn %{"key" => k, "value" => v} -> {k, v} end)
  end

  defp read_type(%{"name" => "null"}), do: %Type.Null{}
  defp read_type(%{"name" => "bool"}), do: %Type.Bool{}

  defp read_type(%{"name" => "int", "bitWidth" => bw, "isSigned" => signed}) do
    %Type.Int{bit_width: bw, signed: signed}
  end

  defp read_type(%{"name" => "floatingpoint", "precision" => p}) do
    %Type.FloatingPoint{precision: precision_atom(p)}
  end

  defp read_type(%{"name" => "utf8"}), do: %Type.Utf8{}
  defp read_type(%{"name" => "binary"}), do: %Type.Binary{}

  defp read_type(%{"name" => "date", "unit" => unit}) do
    %Type.Date{unit: date_unit_atom(unit)}
  end

  defp read_type(%{"name" => "timestamp"} = m) do
    %Type.Timestamp{
      unit: time_unit_atom(m["unit"]),
      timezone: m["timezone"]
    }
  end

  defp read_type(%{"name" => "list"}), do: %Type.List{}
  defp read_type(%{"name" => "struct"}), do: %Type.Struct{}
  defp read_type(other), do: raise(ArgumentError, "unsupported type: #{inspect(other)}")

  defp precision_atom("HALF"), do: :half
  defp precision_atom("SINGLE"), do: :single
  defp precision_atom("DOUBLE"), do: :double

  defp date_unit_atom("DAY"), do: :day
  defp date_unit_atom("MILLISECOND"), do: :millisecond

  defp time_unit_atom("SECOND"), do: :second
  defp time_unit_atom("MILLISECOND"), do: :millisecond
  defp time_unit_atom("MICROSECOND"), do: :microsecond
  defp time_unit_atom("NANOSECOND"), do: :nanosecond

  ## ---------------------------------------------------------------------
  ## Batches and columns
  ## ---------------------------------------------------------------------

  defp read_batch(%{"count" => count, "columns" => cols}, %Schema{fields: fields}) do
    if length(cols) != length(fields) do
      raise ArgumentError, "batch has #{length(cols)} columns but schema has #{length(fields)}"
    end

    columns =
      fields
      |> Enum.zip(cols)
      |> Enum.map(fn {field, col} -> read_column(col, field, count) end)

    %RecordBatch{
      schema: %Schema{fields: fields},
      length: count,
      columns: columns
    }
  end

  defp read_column(col, %Field{type: type, children: children}, batch_count) do
    count = Map.get(col, "count", batch_count)
    read_column_by_type(type, col, count, children)
  end

  ## ----- Null -----
  defp read_column_by_type(%Type.Null{}, _col, count, _children) do
    %Array.Null{length: count}
  end

  ## ----- Bool -----
  defp read_column_by_type(%Type.Bool{}, col, count, _children) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)
    values = col |> Map.fetch!("DATA") |> Buffer.pack_bool_values()

    %Array.Bool{
      length: count,
      null_count: null_count,
      validity: validity,
      values: values
    }
  end

  ## ----- Int -----
  defp read_column_by_type(%Type.Int{bit_width: bw, signed: signed}, col, count, _children) do
    kind = int_kind(bw, signed)
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)

    values =
      col |> Map.fetch!("DATA") |> Enum.map(&parse_integer/1) |> Buffer.pack_primitive(kind)

    struct!(array_mod_for_int(bw, signed), %{
      length: count,
      null_count: null_count,
      validity: validity,
      values: values
    })
  end

  ## ----- Float -----
  defp read_column_by_type(%Type.FloatingPoint{precision: prec}, col, count, _children) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)
    kind = float_kind(prec)
    values = col |> Map.fetch!("DATA") |> Enum.map(&parse_number/1) |> Buffer.pack_primitive(kind)

    struct!(array_mod_for_float(prec), %{
      length: count,
      null_count: null_count,
      validity: validity,
      values: values
    })
  end

  ## ----- Date -----
  defp read_column_by_type(%Type.Date{unit: :day}, col, count, _children) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)

    values =
      col |> Map.fetch!("DATA") |> Enum.map(&parse_integer/1) |> Buffer.pack_primitive(:int32)

    %Array.Date32{
      length: count,
      null_count: null_count,
      validity: validity,
      values: values
    }
  end

  defp read_column_by_type(%Type.Date{unit: :millisecond}, col, count, _children) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)

    values =
      col |> Map.fetch!("DATA") |> Enum.map(&parse_integer/1) |> Buffer.pack_primitive(:int64)

    %Array.Date64{
      length: count,
      null_count: null_count,
      validity: validity,
      values: values
    }
  end

  ## ----- Timestamp -----
  defp read_column_by_type(%Type.Timestamp{unit: unit, timezone: tz}, col, count, _children) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)

    values =
      col |> Map.fetch!("DATA") |> Enum.map(&parse_integer/1) |> Buffer.pack_primitive(:int64)

    %Array.Timestamp{
      unit: unit,
      timezone: tz,
      length: count,
      null_count: null_count,
      validity: validity,
      values: values
    }
  end

  ## ----- Utf8 -----
  defp read_column_by_type(%Type.Utf8{}, col, count, _children) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)
    data = Map.fetch!(col, "DATA")
    offsets = Buffer.pack_int32_offsets(Enum.map(data, &byte_size/1))
    values = IO.iodata_to_binary(data)

    %Array.Utf8{
      length: count,
      null_count: null_count,
      validity: validity,
      offsets: offsets,
      values: values
    }
  end

  ## ----- Binary -----
  defp read_column_by_type(%Type.Binary{}, col, count, _children) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)
    decoded = col |> Map.fetch!("DATA") |> Enum.map(&decode_hex/1)
    offsets = Buffer.pack_int32_offsets(Enum.map(decoded, &byte_size/1))
    values = IO.iodata_to_binary(decoded)

    %Array.Binary{
      length: count,
      null_count: null_count,
      validity: validity,
      offsets: offsets,
      values: values
    }
  end

  ## ----- List -----
  defp read_column_by_type(%Type.List{}, col, count, [child_field]) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)
    raw_offsets = col |> Map.fetch!("OFFSET") |> Enum.map(&parse_integer/1)

    if length(raw_offsets) != count + 1 do
      raise ArgumentError,
            "list OFFSET must have count+1 entries (got #{length(raw_offsets)} for count #{count})"
    end

    offsets =
      raw_offsets
      |> Enum.map(&<<&1::little-signed-32>>)
      |> IO.iodata_to_binary()

    [child_col] = Map.fetch!(col, "children")
    child_count = List.last(raw_offsets)
    child_array = read_column(child_col, child_field, child_count)

    %Array.List{
      length: count,
      null_count: null_count,
      validity: validity,
      offsets: offsets,
      values: child_array
    }
  end

  ## ----- Struct -----
  defp read_column_by_type(%Type.Struct{}, col, count, child_fields) do
    {validity, null_count} = pack_validity_field(col["VALIDITY"], count)
    child_cols = Map.fetch!(col, "children")

    if length(child_cols) != length(child_fields) do
      raise ArgumentError,
            "struct has #{length(child_cols)} child columns but schema has #{length(child_fields)} child fields"
    end

    children =
      child_fields
      |> Enum.zip(child_cols)
      |> Enum.map(fn {f, c} -> read_column(c, f, count) end)

    %Array.Struct{
      length: count,
      null_count: null_count,
      validity: validity,
      children: children
    }
  end

  ## ---------------------------------------------------------------------
  ## Validity helpers
  ## ---------------------------------------------------------------------

  defp pack_validity_field(nil, _count), do: {nil, 0}

  defp pack_validity_field(flags, count) when is_list(flags) do
    if length(flags) != count do
      raise ArgumentError,
            "VALIDITY has #{length(flags)} entries but column count is #{count}"
    end

    Buffer.pack_validity(flags)
  end

  ## ---------------------------------------------------------------------
  ## Numeric / type tag helpers
  ## ---------------------------------------------------------------------

  defp int_kind(8, true), do: :int8
  defp int_kind(16, true), do: :int16
  defp int_kind(32, true), do: :int32
  defp int_kind(64, true), do: :int64
  defp int_kind(8, false), do: :uint8
  defp int_kind(16, false), do: :uint16
  defp int_kind(32, false), do: :uint32
  defp int_kind(64, false), do: :uint64

  defp float_kind(:half), do: :float32
  defp float_kind(:single), do: :float32
  defp float_kind(:double), do: :float64

  defp array_mod_for_int(8, true), do: Array.Int8
  defp array_mod_for_int(16, true), do: Array.Int16
  defp array_mod_for_int(32, true), do: Array.Int32
  defp array_mod_for_int(64, true), do: Array.Int64
  defp array_mod_for_int(8, false), do: Array.UInt8
  defp array_mod_for_int(16, false), do: Array.UInt16
  defp array_mod_for_int(32, false), do: Array.UInt32
  defp array_mod_for_int(64, false), do: Array.UInt64

  defp array_mod_for_float(:single), do: Array.Float32
  defp array_mod_for_float(:double), do: Array.Float64

  defp parse_integer(v) when is_integer(v), do: v
  defp parse_integer(v) when is_binary(v), do: String.to_integer(v)

  defp parse_number(v) when is_number(v), do: v / 1
  defp parse_number(v) when is_binary(v), do: String.to_float(v)

  defp decode_hex(hex) when is_binary(hex) do
    hex |> String.upcase() |> Base.decode16!()
  end
end
