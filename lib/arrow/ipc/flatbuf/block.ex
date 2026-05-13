defmodule Arrow.Ipc.Flatbuf.Block do
  @moduledoc "Generated from FlatBuffers struct Arrow.Ipc.Flatbuf.Block. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  defstruct offset: 0, metaDataLength: 0, bodyLength: 0
  @type t :: %__MODULE__{offset: integer(), metaDataLength: integer(), bodyLength: integer()}

  @doc false
  def __flatbuf__(:struct_size), do: 24
  def __flatbuf__(:struct_align), do: 8

  @doc "Decode a struct from `buf` at the given absolute position."
  @spec decode_at(binary(), non_neg_integer()) :: t()
  def decode_at(buf, pos) do
    %__MODULE__{
      offset: Wire.read_i64(buf, pos + 0),
      metaDataLength: Wire.read_i32(buf, pos + 8),
      bodyLength: Wire.read_i64(buf, pos + 16)
    }
  end

  @doc "Serialize this struct to a binary of exactly `24` bytes."
  @spec encode(t() | map()) :: binary()
  def encode(value) do
    _ = value

    <<Map.get(value, :offset, 0)::little-signed-64,
      Map.get(value, :metaDataLength, 0)::little-signed-32, <<0::size(32)>>,
      Map.get(value, :bodyLength, 0)::little-signed-64>>
  end
end
