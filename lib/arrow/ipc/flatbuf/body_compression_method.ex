defmodule Arrow.Ipc.Flatbuf.BodyCompressionMethod do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.BodyCompressionMethod. Do not edit."

  @type t :: :BUFFER

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:BUFFER), do: 0

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :BUFFER
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:BUFFER]

  @doc false
  def __flatbuf__(:underlying_type), do: :i8
end
