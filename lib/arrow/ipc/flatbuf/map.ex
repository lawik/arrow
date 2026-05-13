defmodule Arrow.Ipc.Flatbuf.Map do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Map. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct keysSorted: false
  @type t :: %__MODULE__{keysSorted: boolean()}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      keysSorted: decode_field_keysSorted(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)

    b =
      Wire.add_field_scalar(
        b,
        4,
        if(Map.get(value, :keysSorted, false), do: 1, else: 0),
        0,
        &Wire.push_u8/2
      )

    Wire.end_table(b)
  end

  @doc "Read field `keysSorted` from a table at position `pos`. Returns the field value or its default."
  def decode_field_keysSorted(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> false
      o -> Wire.read_bool(buf, pos + o)
    end
  end
end
