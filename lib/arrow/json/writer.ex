defmodule Arrow.Json.Writer do
  @moduledoc """
  Emits Arrow integration test JSON form from in-memory `Arrow.Schema` and
  `Arrow.RecordBatch` structs.

  The output is a plain Elixir map / list shape suitable for `Jason.encode/1`.
  Numeric types whose range can exceed JSON's 2^53 limit (Int64, UInt64,
  Date64, Timestamp) are written as decimal strings, matching the reference
  C++ writer. Binary columns are written as uppercase hex strings.
  """

  alias Arrow.{Array, Buffer, Field, RecordBatch, Schema, Type}

  @doc """
  Converts a schema + batches (+ optional dictionaries registry) into
  the JSON-form map.
  """
  @spec write(
          Schema.t(),
          [RecordBatch.t()],
          %{optional(non_neg_integer()) => Arrow.Array.t()}
        ) :: map()
  def write(%Schema{} = schema, batches, dictionaries \\ %{})
      when is_list(batches) and is_map(dictionaries) do
    base = %{
      "schema" => write_schema(schema),
      "batches" => Enum.map(batches, &write_batch(&1, schema))
    }

    if map_size(dictionaries) == 0 do
      base
    else
      Map.put(base, "dictionaries", write_dictionaries(dictionaries, schema))
    end
  end

  defp write_dictionaries(dicts, %Schema{} = schema) do
    Enum.map(dicts, fn {id, array} ->
      field =
        find_field_by_dict_id(schema, id) ||
          raise(ArgumentError, "dictionary id #{id} has no referencing field")

      value_field = %Field{
        name: field.name,
        type: field.type,
        nullable: field.nullable,
        children: field.children,
        metadata: field.metadata
      }

      %{
        "id" => id,
        "data" => %{
          "count" => array_count(array),
          "columns" => [write_column(value_field, array)]
        }
      }
    end)
  end

  defp find_field_by_dict_id(%Schema{fields: fields}, target), do: walk_for_dict(fields, target)

  defp walk_for_dict(fields, target) when is_list(fields) do
    Enum.find_value(fields, fn f -> walk_for_dict(f, target) end)
  end

  defp walk_for_dict(%Field{dictionary: %{id: id}} = f, target) when id == target, do: f

  defp walk_for_dict(%Field{children: children}, target),
    do: walk_for_dict(children, target)

  defp walk_for_dict(_, _), do: nil

  ## ---------------------------------------------------------------------
  ## Schema
  ## ---------------------------------------------------------------------

  defp write_schema(%Schema{fields: fields, metadata: metadata}) do
    base = %{"fields" => Enum.map(fields, &write_field/1)}
    maybe_put_metadata(base, metadata)
  end

  defp write_field(%Field{} = f) do
    base = %{
      "name" => f.name,
      "type" => write_type(f.type),
      "nullable" => f.nullable,
      "children" => Enum.map(f.children, &write_field/1)
    }

    base
    |> maybe_put_metadata(f.metadata)
    |> maybe_put_dictionary(f.dictionary)
  end

  defp maybe_put_dictionary(map, nil), do: map

  defp maybe_put_dictionary(map, %Arrow.Type.DictionaryEncoding{} = d) do
    Map.put(map, "dictionary", %{
      "id" => d.id,
      "indexType" => write_type(d.index_type),
      "isOrdered" => d.is_ordered
    })
  end

  defp maybe_put_metadata(map, %{} = m) when map_size(m) == 0, do: map

  defp maybe_put_metadata(map, %{} = m) do
    Map.put(map, "metadata", Enum.map(m, fn {k, v} -> %{"key" => k, "value" => v} end))
  end

  defp write_type(%Type.Null{}), do: %{"name" => "null"}
  defp write_type(%Type.Bool{}), do: %{"name" => "bool"}

  defp write_type(%Type.Int{bit_width: bw, signed: signed}) do
    %{"name" => "int", "bitWidth" => bw, "isSigned" => signed}
  end

  defp write_type(%Type.FloatingPoint{precision: p}) do
    %{"name" => "floatingpoint", "precision" => precision_string(p)}
  end

  defp write_type(%Type.Utf8{}), do: %{"name" => "utf8"}
  defp write_type(%Type.Binary{}), do: %{"name" => "binary"}

  defp write_type(%Type.Date{unit: unit}) do
    %{"name" => "date", "unit" => date_unit_string(unit)}
  end

  defp write_type(%Type.Timestamp{unit: unit, timezone: tz}) do
    base = %{"name" => "timestamp", "unit" => time_unit_string(unit)}
    if tz, do: Map.put(base, "timezone", tz), else: base
  end

  defp write_type(%Type.List{}), do: %{"name" => "list"}
  defp write_type(%Type.Struct{}), do: %{"name" => "struct"}

  defp write_type(%Type.Time{bit_width: bw, unit: unit}) do
    %{"name" => "time", "bitWidth" => bw, "unit" => time_unit_string(unit)}
  end

  defp write_type(%Type.Duration{unit: unit}) do
    %{"name" => "duration", "unit" => time_unit_string(unit)}
  end

  defp write_type(%Type.FixedSizeBinary{byte_width: bw}) do
    %{"name" => "fixedsizebinary", "byteWidth" => bw}
  end

  defp write_type(%Type.FixedSizeList{list_size: n}) do
    %{"name" => "fixedsizelist", "listSize" => n}
  end

  defp write_type(%Type.Decimal{bit_width: bw, precision: p, scale: s}) do
    %{"name" => "decimal", "bitWidth" => bw, "precision" => p, "scale" => s}
  end

  defp write_type(%Type.Map{keys_sorted: ks}) do
    %{"name" => "map", "keysSorted" => ks}
  end

  defp precision_string(:half), do: "HALF"
  defp precision_string(:single), do: "SINGLE"
  defp precision_string(:double), do: "DOUBLE"

  defp date_unit_string(:day), do: "DAY"
  defp date_unit_string(:millisecond), do: "MILLISECOND"

  defp time_unit_string(:second), do: "SECOND"
  defp time_unit_string(:millisecond), do: "MILLISECOND"
  defp time_unit_string(:microsecond), do: "MICROSECOND"
  defp time_unit_string(:nanosecond), do: "NANOSECOND"

  ## ---------------------------------------------------------------------
  ## Batches and columns
  ## ---------------------------------------------------------------------

  defp write_batch(%RecordBatch{length: n, columns: cols}, %Schema{fields: fields}) do
    %{
      "count" => n,
      "columns" =>
        fields
        |> Enum.zip(cols)
        |> Enum.map(fn {field, col} -> write_column(field, col) end)
    }
  end

  defp write_column(%Field{dictionary: nil} = field, array) do
    base = %{"name" => field.name, "count" => array_count(array)}
    write_column_body(base, field, array)
  end

  defp write_column(
         %Field{dictionary: %{index_type: idx_type}} = field,
         %Arrow.Array.Dictionary{indices: indices}
       ) do
    # Emit the column body using the index type. The dictionary
    # annotation on the field stays at schema level; the column itself
    # just carries the indices.
    base = %{"name" => field.name, "count" => array_count(indices)}
    write_column_body(base, %Field{field | type: idx_type, dictionary: nil}, indices)
  end

  defp array_count(%Array.Null{length: n}), do: n
  defp array_count(%{length: n}), do: n

  ## ----- Null -----
  defp write_column_body(base, %Field{type: %Type.Null{}}, %Array.Null{}) do
    base
  end

  ## ----- Bool -----
  defp write_column_body(base, %Field{type: %Type.Bool{}}, %Array.Bool{} = a) do
    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", Buffer.unpack_bool_values(a.values, a.length))
  end

  ## ----- Int -----
  defp write_column_body(base, %Field{type: %Type.Int{bit_width: bw, signed: signed}}, array) do
    kind = int_kind(bw, signed)
    values = Buffer.unpack_primitive(array.values, kind, array.length)

    base
    |> Map.put("VALIDITY", validity_list(array.validity, array.length))
    |> Map.put("DATA", maybe_stringify_int(values, bw))
  end

  ## ----- Float -----
  defp write_column_body(base, %Field{type: %Type.FloatingPoint{precision: p}}, array) do
    values = Buffer.unpack_primitive(array.values, float_kind(p), array.length)

    base
    |> Map.put("VALIDITY", validity_list(array.validity, array.length))
    |> Map.put("DATA", Enum.map(values, &(&1 / 1)))
  end

  ## ----- Date -----
  defp write_column_body(base, %Field{type: %Type.Date{unit: :day}}, %Array.Date32{} = a) do
    values = Buffer.unpack_primitive(a.values, :int32, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", values)
  end

  defp write_column_body(base, %Field{type: %Type.Date{unit: :millisecond}}, %Array.Date64{} = a) do
    values = Buffer.unpack_primitive(a.values, :int64, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", Enum.map(values, &Integer.to_string/1))
  end

  ## ----- Timestamp -----
  defp write_column_body(base, %Field{type: %Type.Timestamp{}}, %Array.Timestamp{} = a) do
    values = Buffer.unpack_primitive(a.values, :int64, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", Enum.map(values, &Integer.to_string/1))
  end

  ## ----- Utf8 -----
  defp write_column_body(base, %Field{type: %Type.Utf8{}}, %Array.Utf8{} = a) do
    strings = Buffer.slice_variable(a.offsets, a.values, a.length)
    offsets = Buffer.unpack_int32_offsets(a.offsets, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("OFFSET", offsets)
    |> Map.put("DATA", strings)
  end

  ## ----- Binary -----
  defp write_column_body(base, %Field{type: %Type.Binary{}}, %Array.Binary{} = a) do
    chunks = Buffer.slice_variable(a.offsets, a.values, a.length)
    offsets = Buffer.unpack_int32_offsets(a.offsets, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("OFFSET", offsets)
    |> Map.put("DATA", Enum.map(chunks, &Base.encode16/1))
  end

  ## ----- List -----
  defp write_column_body(
         base,
         %Field{type: %Type.List{}, children: [child_field]},
         %Array.List{} = a
       ) do
    offsets = Buffer.unpack_int32_offsets(a.offsets, a.length)
    child_column = write_column(child_field, a.values)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("OFFSET", offsets)
    |> Map.put("children", [child_column])
  end

  ## ----- Struct -----
  defp write_column_body(
         base,
         %Field{type: %Type.Struct{}, children: child_fields},
         %Array.Struct{} = a
       ) do
    children =
      child_fields
      |> Enum.zip(a.children)
      |> Enum.map(fn {f, c} -> write_column(f, c) end)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("children", children)
  end

  ## ----- Time -----
  defp write_column_body(base, %Field{type: %Type.Time{bit_width: 32}}, %Array.Time32{} = a) do
    values = Buffer.unpack_primitive(a.values, :int32, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", values)
  end

  defp write_column_body(base, %Field{type: %Type.Time{bit_width: 64}}, %Array.Time64{} = a) do
    values = Buffer.unpack_primitive(a.values, :int64, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", Enum.map(values, &Integer.to_string/1))
  end

  ## ----- Duration -----
  defp write_column_body(base, %Field{type: %Type.Duration{}}, %Array.Duration{} = a) do
    values = Buffer.unpack_primitive(a.values, :int64, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", Enum.map(values, &Integer.to_string/1))
  end

  ## ----- FixedSizeBinary -----
  defp write_column_body(
         base,
         %Field{type: %Type.FixedSizeBinary{byte_width: bw}},
         %Array.FixedSizeBinary{} = a
       ) do
    data =
      for <<slot::binary-size(bw) <- a.values>>, do: Base.encode16(slot)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", data)
  end

  ## ----- FixedSizeList -----
  defp write_column_body(
         base,
         %Field{type: %Type.FixedSizeList{}, children: [child_field]},
         %Array.FixedSizeList{} = a
       ) do
    child_column = write_column(child_field, a.values)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("children", [child_column])
  end

  ## ----- Decimal128 -----
  defp write_column_body(
         base,
         %Field{type: %Type.Decimal{bit_width: 128}},
         %Array.Decimal128{} = a
       ) do
    values = unpack_decimal128(a.values, a.length)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("DATA", Enum.map(values, &Integer.to_string/1))
  end

  ## ----- Map -----
  defp write_column_body(
         base,
         %Field{type: %Type.Map{}, children: [entries_field]},
         %Array.Map{} = a
       ) do
    offsets = Buffer.unpack_int32_offsets(a.offsets, a.length)
    entries_column = write_column(entries_field, a.values)

    base
    |> Map.put("VALIDITY", validity_list(a.validity, a.length))
    |> Map.put("OFFSET", offsets)
    |> Map.put("children", [entries_column])
  end

  defp unpack_decimal128(<<>>, 0), do: []

  defp unpack_decimal128(binary, length) when length > 0 do
    do_unpack_decimal128(binary, length, [])
  end

  defp do_unpack_decimal128(_binary, 0, acc), do: Enum.reverse(acc)

  defp do_unpack_decimal128(<<v::little-signed-128, rest::binary>>, n, acc) do
    do_unpack_decimal128(rest, n - 1, [v | acc])
  end

  ## ---------------------------------------------------------------------
  ## Helpers
  ## ---------------------------------------------------------------------

  defp validity_list(nil, length), do: List.duplicate(1, length)
  defp validity_list(bitmap, length), do: Buffer.unpack_validity(bitmap, length)

  defp int_kind(8, true), do: :int8
  defp int_kind(16, true), do: :int16
  defp int_kind(32, true), do: :int32
  defp int_kind(64, true), do: :int64
  defp int_kind(8, false), do: :uint8
  defp int_kind(16, false), do: :uint16
  defp int_kind(32, false), do: :uint32
  defp int_kind(64, false), do: :uint64

  defp float_kind(:single), do: :float32
  defp float_kind(:double), do: :float64
  defp float_kind(:half), do: :float32

  defp maybe_stringify_int(values, 64), do: Enum.map(values, &Integer.to_string/1)
  defp maybe_stringify_int(values, _bw), do: values
end
