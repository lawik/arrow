defmodule Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis. Do not edit."

  @type t :: :Row | :Column

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:Row), do: 0
  def value(:Column), do: 1

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :Row
  def from_value(1), do: :Column
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:Row, :Column]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
