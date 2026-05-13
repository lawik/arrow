defmodule Arrow.Ipc.Flatbuf.TensorDim do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.TensorDim. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct size: 0, name: nil
  @type t :: %__MODULE__{size: integer() | nil, name: String.t() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      size: decode_field_size(buf, pos),
      name: decode_field_name(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_name} =
      case Map.get(value, :name) do
        nil -> {b, nil}
        "" -> Wire.create_string(b, "")
        s when is_binary(s) -> Wire.create_string(b, s)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 6, addr_name)
    b = Wire.add_field_scalar(b, 4, Map.get(value, :size, 0), 0, &Wire.push_i64/2)
    Wire.end_table(b)
  end

  @doc "Read field `size` from a table at position `pos`. Returns the field value or its default."
  def decode_field_size(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> 0
      o -> Wire.read_i64(buf, pos + o)
    end
  end

  @doc "Read field `name` from a table at position `pos`. Returns the field value or its default."
  def decode_field_name(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Wire.read_string_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end
end
