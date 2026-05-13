defmodule Arrow.Ipc.Flatbuf.Message do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Message. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct version: :V1, header: nil, bodyLength: 0, custom_metadata: []

  @type t :: %__MODULE__{
          version: Arrow.Ipc.Flatbuf.MetadataVersion.t() | nil,
          header: Arrow.Ipc.Flatbuf.MessageHeader.t(),
          bodyLength: integer() | nil,
          custom_metadata: [Arrow.Ipc.Flatbuf.KeyValue.t() | nil]
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      version: decode_field_version(buf, pos),
      header: decode_field_header(buf, pos),
      bodyLength: decode_field_bodyLength(buf, pos),
      custom_metadata: decode_field_custom_metadata(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, disc_header, addr_header} =
      case Map.get(value, :header) do
        nil ->
          {b, 0, nil}

        {variant_atom, variant_value} ->
          {b2, addr} =
            Arrow.Ipc.Flatbuf.MessageHeader.build_variant(b, variant_atom, variant_value)

          {b2, Arrow.Ipc.Flatbuf.MessageHeader.discriminator(variant_atom), addr}
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
    b = Wire.add_field_scalar(b, 10, Map.get(value, :bodyLength, 0), 0, &Wire.push_i64/2)
    b = Wire.add_field_offset(b, 8, addr_header)
    b = Wire.add_field_scalar(b, 6, disc_header, 0, &Wire.push_u8/2)

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

  @doc "Read field `header` from a table at position `pos`. Returns the field value or its default."
  def decode_field_header(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 ->
        nil

      type_o ->
        case Wire.read_vtable_field(buf, pos, 8) do
          0 ->
            nil

          value_o ->
            disc = Wire.read_u8(buf, pos + type_o)
            abs_pos = Wire.follow_uoffset(buf, pos + value_o)
            Arrow.Ipc.Flatbuf.MessageHeader.decode_variant(buf, disc, abs_pos)
        end
    end
  end

  @doc "Read field `bodyLength` from a table at position `pos`. Returns the field value or its default."
  def decode_field_bodyLength(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 10) do
      0 -> 0
      o -> Wire.read_i64(buf, pos + o)
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
