defmodule Arrow.Ipc.Flatbuf.FixedSizeList do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.FixedSizeList. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct listSize: 0
  @type t :: %__MODULE__{listSize: integer() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      listSize: decode_field_listSize(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :listSize, 0), 0, &Wire.push_i32/2)
    Wire.end_table(b)
  end

  @doc "Read field `listSize` from a table at position `pos`. Returns the field value or its default."
  def decode_field_listSize(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i32(buf, pos + o)
    end
  end
end
