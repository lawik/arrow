defmodule Arrow.Ipc.Flatbuf.Schema do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Schema. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct endianness: :Little, fields: [], custom_metadata: [], features: []

  @type t :: %__MODULE__{
          endianness: Arrow.Ipc.Flatbuf.Endianness.t() | nil,
          fields: [Arrow.Ipc.Flatbuf.Field.t() | nil],
          custom_metadata: [Arrow.Ipc.Flatbuf.KeyValue.t() | nil],
          features: [Arrow.Ipc.Flatbuf.Feature.t() | nil]
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      endianness: decode_field_endianness(buf, pos),
      fields: decode_field_fields(buf, pos),
      custom_metadata: decode_field_custom_metadata(buf, pos),
      features: decode_field_features(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_fields} =
      case Map.get(value, :fields) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          {addrs, b} =
            Enum.map_reduce(list, b, fn item, acc ->
              {acc2, a} = Arrow.Ipc.Flatbuf.Field.build(acc, item)
              {a, acc2}
            end)

          Wire.create_offset_vector(b, addrs)
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

    {b, addr_features} =
      case Map.get(value, :features) do
        nil ->
          {b, nil}

        list when is_list(list) ->
          ints = Enum.map(list, &Arrow.Ipc.Flatbuf.Feature.value/1)
          Wire.create_scalar_vector(b, ints, 8, 8, &Wire.push_i64/2)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 10, addr_features)
    b = Wire.add_field_offset(b, 8, addr_custom_metadata)
    b = Wire.add_field_offset(b, 6, addr_fields)

    b =
      Wire.add_field_scalar(
        b,
        4,
        Arrow.Ipc.Flatbuf.Endianness.value(Map.get(value, :endianness, :Little)),
        0,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc "Read field `endianness` from a table at position `pos`. Returns the field value or its default."
  def decode_field_endianness(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :Little
      o -> Arrow.Ipc.Flatbuf.Endianness.from_value(Wire.read_i16(buf, pos + o))
    end
  end

  @doc "Read field `fields` from a table at position `pos`. Returns the field value or its default."
  def decode_field_fields(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 ->
        []

      o ->
        abs = Wire.follow_uoffset(buf, pos + o)
        count = Wire.read_vector_count(buf, abs)

        if count == 0 do
          []
        else
          for i <- 0..(count - 1) do
            Arrow.Ipc.Flatbuf.Field.decode_at(
              buf,
              Wire.follow_uoffset(buf, Wire.vector_elem_pos(abs, i, 4))
            )
          end
        end
    end
  end

  @doc "Read field `custom_metadata` from a table at position `pos`. Returns the field value or its default."
  def decode_field_custom_metadata(buf, pos) do
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
            Arrow.Ipc.Flatbuf.KeyValue.decode_at(
              buf,
              Wire.follow_uoffset(buf, Wire.vector_elem_pos(abs, i, 4))
            )
          end
        end
    end
  end

  @doc "Read field `features` from a table at position `pos`. Returns the field value or its default."
  def decode_field_features(buf, pos) do
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
            Arrow.Ipc.Flatbuf.Feature.from_value(
              Wire.read_i64(buf, Wire.vector_elem_pos(abs, i, 8))
            )
          end
        end
    end
  end
end
