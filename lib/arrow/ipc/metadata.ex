defmodule Arrow.Ipc.Metadata do
  @moduledoc """
  Boundary between Arrow's in-memory data model and the FlatBuffers-encoded
  metadata used by the IPC stream / file formats.

  Arrow's IPC framing carries metadata (schema, record-batch descriptors,
  dictionary-batch descriptors, message envelopes, file footers) as
  FlatBuffers. This module is the only place that knows how to translate
  between our `Arrow.Schema` / `Arrow.Field` / `Arrow.Type.*` and the
  generated `Arrow.Ipc.Flatbuf.*` structs.

  ## Current coverage

  - `encode_schema/1` and `decode_schema/1` — the Schema FlatBuffers root.
    Covers every Tier 1 + Tier 2 logical type. Tier 3 variants
    (`LargeBinary`, `LargeUtf8`, `LargeList`, `LargeListView`, `ListView`,
    `BinaryView`, `Utf8View`, `RunEndEncoded`, `Union`, `Interval`) raise
    `ArgumentError` until they're added to `Arrow.Type.*`.
  - Dictionary-encoded fields are rejected on decode; encode raises if a
    field carries dictionary metadata. We don't yet model dictionary
    encoding in `Arrow.Field`.

  Forthcoming: `encode_record_batch/2` / `decode_record_batch/2` for the
  RecordBatch metadata table, plus the Message envelope.
  """

  alias Arrow.Ipc.{Body, Flatbuf}
  alias Arrow.Ipc.Flatbuf.Wire

  ## ---------------------------------------------------------------------
  ## Schema
  ## ---------------------------------------------------------------------

  @doc """
  Encodes an `Arrow.Schema` into a standalone FlatBuffers buffer with
  `Arrow.Ipc.Flatbuf.Schema` as the root table.
  """
  @spec encode_schema(Arrow.Schema.t()) :: binary()
  def encode_schema(%Arrow.Schema{} = schema) do
    builder = Wire.new_builder()
    {builder, addr} = Flatbuf.Schema.build(builder, to_fb_schema(schema))

    builder
    |> Wire.finish(addr)
    |> Wire.to_binary()
  end

  @doc """
  Decodes a FlatBuffers buffer whose root is `Arrow.Ipc.Flatbuf.Schema`
  into an `Arrow.Schema`.
  """
  @spec decode_schema(binary()) :: {:ok, Arrow.Schema.t()} | {:error, term()}
  def decode_schema(binary) when is_binary(binary) do
    pos = Wire.root_table_pos(binary)
    fb = Flatbuf.Schema.decode_at(binary, pos)
    {:ok, from_fb_schema(fb)}
  rescue
    e -> {:error, e}
  end

  ## ---------------------------------------------------------------------
  ## RecordBatch
  ## ---------------------------------------------------------------------

  @doc """
  Encodes an `Arrow.RecordBatch` into a standalone FlatBuffers buffer
  rooted at `Arrow.Ipc.Flatbuf.RecordBatch`, plus the raw 8-byte-aligned
  body bytes those descriptors point into.

  The two binaries are independent: the metadata travels in the IPC
  message envelope, the body bytes travel after it.
  """
  @spec encode_record_batch(Arrow.RecordBatch.t()) ::
          %{metadata: binary(), body: binary(), length: non_neg_integer()}
  def encode_record_batch(%Arrow.RecordBatch{} = batch) do
    %{length: row_count, nodes: nodes, buffers: buffers, body: body} = Body.encode(batch)

    builder = Wire.new_builder()

    {builder, addr} =
      Flatbuf.RecordBatch.build(builder, %{
        length: row_count,
        nodes: nodes,
        buffers: buffers
      })

    metadata =
      builder
      |> Wire.finish(addr)
      |> Wire.to_binary()

    %{metadata: metadata, body: body, length: row_count}
  end

  @doc """
  Decodes a FlatBuffers buffer whose root is
  `Arrow.Ipc.Flatbuf.RecordBatch`, combined with a previously-parsed
  `Arrow.Schema` and the body bytes, into an `Arrow.RecordBatch`.
  """
  @spec decode_record_batch(binary(), binary(), Arrow.Schema.t()) ::
          {:ok, Arrow.RecordBatch.t()} | {:error, term()}
  def decode_record_batch(metadata, body, %Arrow.Schema{} = schema)
      when is_binary(metadata) and is_binary(body) do
    pos = Wire.root_table_pos(metadata)
    fb = Flatbuf.RecordBatch.decode_at(metadata, pos)

    nodes = Enum.map(fb.nodes, fn n -> %{length: n.length, null_count: n.null_count} end)
    buffers = Enum.map(fb.buffers, fn b -> %{offset: b.offset, length: b.length} end)

    {:ok, Body.decode(schema, fb.length, nodes, buffers, body)}
  rescue
    e -> {:error, e}
  end

  ## ---------------------------------------------------------------------
  ## Schema ↔ FB (public conversion API, used by Arrow.Ipc.Stream)
  ## ---------------------------------------------------------------------

  @doc """
  Converts an `Arrow.Schema` to the map shape accepted by
  `Arrow.Ipc.Flatbuf.Schema.build/2`. Exposed so the stream/message
  encoder can drop a Schema into a `MessageHeader` union without
  re-encoding a standalone buffer.
  """
  @spec schema_to_fb_map(Arrow.Schema.t()) :: map()
  def schema_to_fb_map(%Arrow.Schema{} = schema), do: to_fb_schema(schema)

  @doc """
  Converts an `Arrow.Ipc.Flatbuf.Schema` struct (as produced by
  `decode_at/2`) back to an `Arrow.Schema`. Exposed for the same
  reason as `schema_to_fb_map/1`.
  """
  @spec schema_from_fb_struct(Flatbuf.Schema.t()) :: Arrow.Schema.t()
  def schema_from_fb_struct(%Flatbuf.Schema{} = fb), do: from_fb_schema(fb)

  defp to_fb_schema(%Arrow.Schema{fields: fields, metadata: metadata}) do
    %{
      endianness: :Little,
      fields: Enum.map(fields, &to_fb_field/1),
      custom_metadata: metadata_to_fb(metadata),
      features: []
    }
  end

  defp from_fb_schema(%Flatbuf.Schema{fields: fields, custom_metadata: cm}) do
    %Arrow.Schema{
      fields: fields |> reject_nils() |> Enum.map(&from_fb_field/1),
      metadata: metadata_from_fb(cm)
    }
  end

  ## ---------------------------------------------------------------------
  ## Field ↔ FB
  ## ---------------------------------------------------------------------

  defp to_fb_field(%Arrow.Field{} = f) do
    %{
      name: f.name,
      nullable: f.nullable,
      type: type_to_fb(f.type),
      children: Enum.map(f.children, &to_fb_field/1),
      custom_metadata: metadata_to_fb(f.metadata)
    }
  end

  defp from_fb_field(%Flatbuf.Field{dictionary: dict}) when not is_nil(dict) do
    raise ArgumentError, "dictionary-encoded fields are not yet supported"
  end

  defp from_fb_field(%Flatbuf.Field{} = f) do
    %Arrow.Field{
      name: f.name,
      nullable: f.nullable,
      type: type_from_fb(f.type),
      children: f.children |> reject_nils() |> Enum.map(&from_fb_field/1),
      metadata: metadata_from_fb(f.custom_metadata)
    }
  end

  ## ---------------------------------------------------------------------
  ## Type ↔ FB
  ## ---------------------------------------------------------------------

  defp type_to_fb(%Arrow.Type.Null{}), do: {:Null, %{}}
  defp type_to_fb(%Arrow.Type.Bool{}), do: {:Bool, %{}}

  defp type_to_fb(%Arrow.Type.Int{bit_width: bw, signed: signed}) do
    {:Int, %{bitWidth: bw, is_signed: signed}}
  end

  defp type_to_fb(%Arrow.Type.FloatingPoint{precision: p}) do
    {:FloatingPoint, %{precision: fb_precision(p)}}
  end

  defp type_to_fb(%Arrow.Type.Utf8{}), do: {:Utf8, %{}}
  defp type_to_fb(%Arrow.Type.Binary{}), do: {:Binary, %{}}

  defp type_to_fb(%Arrow.Type.Date{unit: u}) do
    {:Date, %{unit: fb_date_unit(u)}}
  end

  defp type_to_fb(%Arrow.Type.Time{bit_width: bw, unit: u}) do
    {:Time, %{bitWidth: bw, unit: fb_time_unit(u)}}
  end

  defp type_to_fb(%Arrow.Type.Timestamp{unit: u, timezone: tz}) do
    {:Timestamp, %{unit: fb_time_unit(u), timezone: tz || ""}}
  end

  defp type_to_fb(%Arrow.Type.Duration{unit: u}) do
    {:Duration, %{unit: fb_time_unit(u)}}
  end

  defp type_to_fb(%Arrow.Type.Decimal{bit_width: bw, precision: p, scale: s}) do
    {:Decimal, %{bitWidth: bw, precision: p, scale: s}}
  end

  defp type_to_fb(%Arrow.Type.FixedSizeBinary{byte_width: bw}) do
    {:FixedSizeBinary, %{byteWidth: bw}}
  end

  defp type_to_fb(%Arrow.Type.FixedSizeList{list_size: n}) do
    {:FixedSizeList, %{listSize: n}}
  end

  defp type_to_fb(%Arrow.Type.List{}), do: {:List, %{}}
  defp type_to_fb(%Arrow.Type.Struct{}), do: {:Struct_, %{}}

  defp type_to_fb(%Arrow.Type.Map{keys_sorted: ks}) do
    {:Map, %{keysSorted: ks}}
  end

  defp type_from_fb({:Null, _}), do: %Arrow.Type.Null{}
  defp type_from_fb({:Bool, _}), do: %Arrow.Type.Bool{}

  defp type_from_fb({:Int, %Flatbuf.Int{bitWidth: bw, is_signed: signed}}) do
    %Arrow.Type.Int{bit_width: bw, signed: signed}
  end

  defp type_from_fb({:FloatingPoint, %Flatbuf.FloatingPoint{precision: p}}) do
    %Arrow.Type.FloatingPoint{precision: from_fb_precision(p)}
  end

  defp type_from_fb({:Utf8, _}), do: %Arrow.Type.Utf8{}
  defp type_from_fb({:Binary, _}), do: %Arrow.Type.Binary{}

  defp type_from_fb({:Date, %Flatbuf.Date{unit: u}}) do
    %Arrow.Type.Date{unit: from_fb_date_unit(u)}
  end

  defp type_from_fb({:Time, %Flatbuf.Time{bitWidth: bw, unit: u}}) do
    %Arrow.Type.Time{bit_width: bw, unit: from_fb_time_unit(u)}
  end

  defp type_from_fb({:Timestamp, %Flatbuf.Timestamp{unit: u, timezone: tz}}) do
    %Arrow.Type.Timestamp{unit: from_fb_time_unit(u), timezone: nil_if_empty(tz)}
  end

  defp type_from_fb({:Duration, %Flatbuf.Duration{unit: u}}) do
    %Arrow.Type.Duration{unit: from_fb_time_unit(u)}
  end

  defp type_from_fb({:Decimal, %Flatbuf.Decimal{bitWidth: bw, precision: p, scale: s}}) do
    %Arrow.Type.Decimal{bit_width: bw, precision: p, scale: s}
  end

  defp type_from_fb({:FixedSizeBinary, %Flatbuf.FixedSizeBinary{byteWidth: bw}}) do
    %Arrow.Type.FixedSizeBinary{byte_width: bw}
  end

  defp type_from_fb({:FixedSizeList, %Flatbuf.FixedSizeList{listSize: n}}) do
    %Arrow.Type.FixedSizeList{list_size: n}
  end

  defp type_from_fb({:List, _}), do: %Arrow.Type.List{}
  defp type_from_fb({:Struct_, _}), do: %Arrow.Type.Struct{}

  defp type_from_fb({:Map, %Flatbuf.Map{keysSorted: ks}}) do
    %Arrow.Type.Map{keys_sorted: ks}
  end

  defp type_from_fb({variant, _})
       when variant in [
              :LargeBinary,
              :LargeUtf8,
              :LargeList,
              :LargeListView,
              :ListView,
              :BinaryView,
              :Utf8View,
              :RunEndEncoded,
              :Union,
              :Interval
            ] do
    raise ArgumentError, "unsupported FB type variant: #{variant}"
  end

  ## ---------------------------------------------------------------------
  ## Enum atom mappings
  ## ---------------------------------------------------------------------

  defp fb_precision(:half), do: :HALF
  defp fb_precision(:single), do: :SINGLE
  defp fb_precision(:double), do: :DOUBLE

  defp from_fb_precision(:HALF), do: :half
  defp from_fb_precision(:SINGLE), do: :single
  defp from_fb_precision(:DOUBLE), do: :double

  defp fb_date_unit(:day), do: :DAY
  defp fb_date_unit(:millisecond), do: :MILLISECOND

  defp from_fb_date_unit(:DAY), do: :day
  defp from_fb_date_unit(:MILLISECOND), do: :millisecond

  defp fb_time_unit(:second), do: :SECOND
  defp fb_time_unit(:millisecond), do: :MILLISECOND
  defp fb_time_unit(:microsecond), do: :MICROSECOND
  defp fb_time_unit(:nanosecond), do: :NANOSECOND

  defp from_fb_time_unit(:SECOND), do: :second
  defp from_fb_time_unit(:MILLISECOND), do: :millisecond
  defp from_fb_time_unit(:MICROSECOND), do: :microsecond
  defp from_fb_time_unit(:NANOSECOND), do: :nanosecond

  ## ---------------------------------------------------------------------
  ## Metadata maps
  ## ---------------------------------------------------------------------

  defp metadata_to_fb(map) when map_size(map) == 0, do: nil

  defp metadata_to_fb(map) do
    Enum.map(map, fn {k, v} -> %{key: k, value: v} end)
  end

  defp metadata_from_fb(nil), do: %{}
  defp metadata_from_fb([]), do: %{}

  defp metadata_from_fb(list) when is_list(list) do
    list
    |> reject_nils()
    |> Map.new(fn %Flatbuf.KeyValue{key: k, value: v} -> {k, v} end)
  end

  ## ---------------------------------------------------------------------
  ## Misc
  ## ---------------------------------------------------------------------

  defp reject_nils(list), do: Enum.reject(list, &is_nil/1)

  defp nil_if_empty(nil), do: nil
  defp nil_if_empty(""), do: nil
  defp nil_if_empty(s), do: s
end
