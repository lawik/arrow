defmodule Arrow.Ipc.Flatbuf.KeyValue do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.KeyValue. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct key: nil, value: nil
  @type t :: %__MODULE__{key: String.t() | nil, value: String.t() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      key: decode_field_key(buf, pos),
      value: decode_field_value(buf, pos)
    }
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder

    {b, addr_key} =
      case Map.get(value, :key) do
        nil -> {b, nil}
        "" -> Wire.create_string(b, "")
        s when is_binary(s) -> Wire.create_string(b, s)
      end

    {b, addr_value} =
      case Map.get(value, :value) do
        nil -> {b, nil}
        "" -> Wire.create_string(b, "")
        s when is_binary(s) -> Wire.create_string(b, s)
      end

    b = Wire.start_table(b)
    b = Wire.add_field_offset(b, 6, addr_value)
    b = Wire.add_field_offset(b, 4, addr_key)
    Wire.end_table(b)
  end

  @doc "Read field `key` from a table at position `pos`. Returns the field value or its default."
  def decode_field_key(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> nil
      o -> Wire.read_string_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end

  @doc "Read field `value` from a table at position `pos`. Returns the field value or its default."
  def decode_field_value(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 6) do
      0 -> nil
      o -> Wire.read_string_at(buf, Wire.follow_uoffset(buf, pos + o))
    end
  end
end
