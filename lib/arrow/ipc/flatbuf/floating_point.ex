defmodule Arrow.Ipc.Flatbuf.FloatingPoint do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.FloatingPoint. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct precision: :HALF
  @type t :: %__MODULE__{precision: Arrow.Ipc.Flatbuf.Precision.t() | nil}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      precision: decode_field_precision(buf, pos)
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
        Arrow.Ipc.Flatbuf.Precision.value(Map.get(value, :precision, :HALF)),
        0,
        &Wire.push_i16/2
      )

    Wire.end_table(b)
  end

  @doc "Read field `precision` from a table at position `pos`. Returns the field value or its default."
  def decode_field_precision(buf, pos) do
    case Wire.read_vtable_field(buf, pos, 4) do
      0 -> :HALF
      o -> Arrow.Ipc.Flatbuf.Precision.from_value(Wire.read_i16(buf, pos + o))
    end
  end
end
