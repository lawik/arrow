defmodule Arrow.Ipc.Flatbuf.ListView do
  @moduledoc "Generated from FlatBuffers table Arrow.Ipc.Flatbuf.ListView. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct []
  @type t :: %__MODULE__{}

  @doc "Decode a table at absolute position `pos` within `buf`."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{}
  end

  @doc "Build this table inside an existing builder. Returns `{builder, addr}`."
  def build(builder, value) when is_map(value) do
    b = builder
    b = Wire.start_table(b)
    Wire.end_table(b)
  end
end
