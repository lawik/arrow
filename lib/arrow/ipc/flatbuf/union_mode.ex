defmodule Arrow.Ipc.Flatbuf.UnionMode do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.UnionMode. Do not edit."

  @type t :: :Sparse | :Dense

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:Sparse), do: 0
  def value(:Dense), do: 1

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :Sparse
  def from_value(1), do: :Dense
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:Sparse, :Dense]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
