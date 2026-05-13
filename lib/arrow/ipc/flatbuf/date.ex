defmodule Arrow.Ipc.Flatbuf.Date do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.Date. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct unit: :MILLISECOND
  @type t :: %__MODULE__{unit: Arrow.Ipc.Flatbuf.DateUnit.t() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      unit: decode_field_unit(buf, pos)
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
        Arrow.Ipc.Flatbuf.DateUnit.value(Map.get(value, :unit, :MILLISECOND)),
        1,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc "Read field `unit` from a table at position `pos`. Returns the field value or its default."
  def decode_field_unit(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :MILLISECOND
      o -> Arrow.Ipc.Flatbuf.DateUnit.from_value(Wire.read_i16(buf, pos + o))
    end
  end
end
