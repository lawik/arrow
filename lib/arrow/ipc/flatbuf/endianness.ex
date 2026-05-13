defmodule Arrow.Ipc.Flatbuf.Endianness do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.Endianness. Do not edit."

  @type t :: :Little | :Big

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:Little), do: 0
  def value(:Big), do: 1

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :Little
  def from_value(1), do: :Big
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:Little, :Big]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
