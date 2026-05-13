defmodule Arrow.Ipc.Flatbuf.Precision do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.Precision. Do not edit."

  @type t :: :HALF | :SINGLE | :DOUBLE

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:HALF), do: 0
  def value(:SINGLE), do: 1
  def value(:DOUBLE), do: 2

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :HALF
  def from_value(1), do: :SINGLE
  def from_value(2), do: :DOUBLE
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:HALF, :SINGLE, :DOUBLE]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
