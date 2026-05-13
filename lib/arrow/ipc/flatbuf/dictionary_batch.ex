defmodule Arrow.Ipc.Flatbuf.DictionaryBatch do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.DictionaryBatch. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct id: 0, data: nil, isDelta: false

  @type t :: %__MODULE__{
          id: integer() | nil,
          data: Arrow.Ipc.Flatbuf.RecordBatch.t() | nil,
          isDelta: boolean()
        }

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      id: decode_field_id(buf, pos),
      data: decode_field_data(buf, pos),
      isDelta: decode_field_isDelta(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_data} =
      case Map.get(value, :data) do
        nil -> {b, nil}
        v -> Arrow.Ipc.Flatbuf.RecordBatch.build(b, v)
      end

    b = Wire.start_table(b)

    b =
      Wire.add_field_scalar(
        b,
        8,
        if(Map.get(value, :isDelta, false), do: 1, else: 0),
        0,
        &Wire.push_u8/2
      )

    b = Wire.add_field_offset(b, 6, addr_data)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :id, 0), 0, &Wire.push_i64/2)
    Wire.end_table(b)
  end

  @doc "Read field `id` from a table at position `pos`. Returns the field value or its default."
  def decode_field_id(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i64(buf, pos + o)
    end
  end

  @doc "Read field `data` from a table at position `pos`. Returns the field value or its default."
  def decode_field_data(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Arrow.Ipc.Flatbuf.RecordBatch.decode_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `isDelta` from a table at position `pos`. Returns the field value or its default."
  def decode_field_isDelta(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 8) do
      0 -> false
      o -> Wire.read_bool(buf, pos + o)
    end
  end
end
