defmodule Arrow.Ipc.Flatbuf.TimeUnit do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.TimeUnit. Do not edit."

  @type t :: :SECOND | :MILLISECOND | :MICROSECOND | :NANOSECOND

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:SECOND), do: 0
  def value(:MILLISECOND), do: 1
  def value(:MICROSECOND), do: 2
  def value(:NANOSECOND), do: 3

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :SECOND
  def from_value(1), do: :MILLISECOND
  def from_value(2), do: :MICROSECOND
  def from_value(3), do: :NANOSECOND
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:SECOND, :MILLISECOND, :MICROSECOND, :NANOSECOND]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
