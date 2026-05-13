defmodule Arrow.Ipc.Flatbuf.IntervalUnit do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.IntervalUnit. Do not edit."

  @type t :: :YEAR_MONTH | :DAY_TIME | :MONTH_DAY_NANO

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:YEAR_MONTH), do: 0
  def value(:DAY_TIME), do: 1
  def value(:MONTH_DAY_NANO), do: 2

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :YEAR_MONTH
  def from_value(1), do: :DAY_TIME
  def from_value(2), do: :MONTH_DAY_NANO
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:YEAR_MONTH, :DAY_TIME, :MONTH_DAY_NANO]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
