defmodule Arrow.Ipc.Flatbuf.Feature do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.Feature. Do not edit."

  @type t :: :UNUSED | :DICTIONARY_REPLACEMENT | :COMPRESSED_BODY

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:UNUSED), do: 0
  def value(:DICTIONARY_REPLACEMENT), do: 1
  def value(:COMPRESSED_BODY), do: 2

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :UNUSED
  def from_value(1), do: :DICTIONARY_REPLACEMENT
  def from_value(2), do: :COMPRESSED_BODY
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:UNUSED, :DICTIONARY_REPLACEMENT, :COMPRESSED_BODY]

  @doc false
  def __flatbuf__(:underlying_type), do: :i64
end
