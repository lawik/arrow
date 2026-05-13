defmodule Arrow.Ipc.Flatbuf.Footer do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Footer. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct version: :V1, schema: nil, dictionaries: [], recordBatches: [], custom_metadata: []

  @type t :: %__MODULE__{
          version: Arrow.Ipc.Flatbuf.MetadataVersion.t() | nil,
          schema: Arrow.Ipc.Flatbuf.Schema.t() | nil,
          dictionaries: [Arrow.Ipc.Flatbuf.Block.t() | nil],
          recordBatches: [Arrow.Ipc.Flatbuf.Block.t() | nil],
          custom_metadata: [Arrow.Ipc.Flatbuf.KeyValue.t() | nil]
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      version: decode_field_version(buf, pos),
      schema: decode_field_schema(buf, pos),
      dictionaries: decode_field_dictionaries(buf, pos),
      recordBatches: decode_field_recordBatches(buf, pos),
      custom_metadata: decode_field_custom_metadata(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_schema} =
      case Map.get(value, :schema) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.Schema.build(b, v)
      end

    {b, addr_dictionaries} =
      case Map.get(value, :dictionaries) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          count = length(list)
          b1 = Wire.start_vector(b, count, 24, 8)

          b2 =
            list
            |> Enum.reverse()
            |> Enum.reduce(b1, fn item, acc ->
              acc = Wire.align(acc, 8)
              bin = Arrow.Ipc.Flatbuf.Block.encode(item)
              %{acc | bytes: [bin | acc.bytes], size: acc.size + byte_size(bin)}
            end)

          Wire.end_vector(b2, count)
      end

    {b, addr_recordBatches} =
      case Map.get(value, :recordBatches) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          count = length(list)
          b1 = Wire.start_vector(b, count, 24, 8)

          b2 =
            list
            |> Enum.reverse()
            |> Enum.reduce(b1, fn item, acc ->
              acc = Wire.align(acc, 8)
              bin = Arrow.Ipc.Flatbuf.Block.encode(item)
              %{acc | bytes: [bin | acc.bytes], size: acc.size + byte_size(bin)}
            end)

          Wire.end_vector(b2, count)
      end

    {b, addr_custom_metadata} =
      case Map.get(value, :custom_metadata) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          {addrs, b} =
            Enum.map_reduce(list, b, fn item, acc ->
              {acc2, a} = Arrow.Ipc.Flatbuf.KeyValue.build(acc, item)
              {a, acc2}
            end)

          Wire.create_offset_vector(b, addrs)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 12, addr_custom_metadata)
    b = Wire.add_field_offset(b, 10, addr_recordBatches)
    b = Wire.add_field_offset(b, 8, addr_dictionaries)
    b = Wire.add_field_offset(b, 6, addr_schema)

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.MetadataVersion.value(Map.get(value, :version, :V1)),
        0,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc "Read field `version` from a table at position `pos`. Returns the field value or its default."
  def decode_field_version(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :V1
      o -> Arrow.Ipc.Flatbuf.MetadataVersion.from_value(Wire.read_i16(buf, pos + o))
    end
  end

  @doc "Read field `schema` from a table at position `pos`. Returns the field value or its default."
  def decode_field_schema(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.Schema.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `dictionaries` from a table at position `pos`. Returns the field value or its default."
  def decode_field_dictionaries(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 ->
        []

      o ->
        abs = Wire.follow_uoffset(buf, pos + o)
        count = Wire.read_vector_count(buf, abs)

        if count == 0 do
          []
        else
          for i <- 0..(count - 1) do
            Arrow.Ipc.Flatbuf.Block.decode_at(buf, Wire.vector_elem_pos(abs, i, 24))
          end
        end
    end
  end

  @doc "Read field `recordBatches` from a table at position `pos`. Returns the field value or its default."
  def decode_field_recordBatches(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 ->
        []

      o ->
        abs = Wire.follow_uoffset(buf, pos + o)
        count = Wire.read_vector_count(buf, abs)

        if count == 0 do
          []
        else
          for i <- 0..(count - 1) do
            Arrow.Ipc.Flatbuf.Block.decode_at(buf, Wire.vector_elem_pos(abs, i, 24))
          end
        end
    end
  end

  @doc "Read field `custom_metadata` from a table at position `pos`. Returns the field value or its default."
  def decode_field_custom_metadata(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 12) do
      0 ->
        []

      o ->
        abs = Wire.follow_uoffset(buf, pos + o)
        count = Wire.read_vector_count(buf, abs)

        if count == 0 do
          []
        else
          for i <- 0..(count - 1) do
            Arrow.Ipc.Flatbuf.KeyValue.decode_at(
              buf,
              Wire.follow_uoffset(buf, Wire.vector_elem_pos(abs, i, 4))
            )
          end
        end
    end
  end
end
