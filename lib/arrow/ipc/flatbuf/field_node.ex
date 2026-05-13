defmodule Arrow.Ipc.Flatbuf.FieldNode do
  @moduledoc "Generated from FlatBuffers struct Arrow.Ipc.Flatbuf.FieldNode. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct length: 0, null_count: 0
  @type t :: %__MODULE__{length: integer(), null_count: integer()}

  @doc false
  def __flatbuf__(:struct_size), do: 16
  def __flatbuf__(:struct_align), do: 8

  @doc "Decode a struct from `buf` at the given absolute position."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      length: Wire.read_i64(buf, pos + 0),
      null_count: Wire.read_i64(buf, pos + 8)
    }
  end

  @doc "Serialize this struct to a binary of exactly `16` bytes."
  @spec encode(t() | map()) :: binary()
  def encode(value) do
    _ = value

    <<Map.get(value, :length, 0)::little-signed-64,
      Map.get(value, :null_count, 0)::little-signed-64>>
  end
end
