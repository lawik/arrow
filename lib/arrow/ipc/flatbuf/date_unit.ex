defmodule Arrow.Ipc.Flatbuf.DateUnit do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.DateUnit. Do not edit."

  @type t :: :DAY | :MILLISECOND

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:DAY), do: 0
  def value(:MILLISECOND), do: 1

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :DAY
  def from_value(1), do: :MILLISECOND
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:DAY, :MILLISECOND]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
