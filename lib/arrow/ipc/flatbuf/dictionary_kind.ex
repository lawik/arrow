defmodule Arrow.Ipc.Flatbuf.DictionaryKind do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.DictionaryKind. Do not edit."

  @type t :: :DenseArray

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:DenseArray), do: 0

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :DenseArray
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:DenseArray]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
