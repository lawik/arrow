defmodule Arrow.Ipc.Flatbuf.MetadataVersion do
  @moduledoc "Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.MetadataVersion. Do not edit."

  @type t :: :V1 | :V2 | :V3 | :V4 | :V5

  @doc "Return the integer value of a variant."
  @spec value(t()) :: integer()
  def value(:V1), do: 0
  def value(:V2), do: 1
  def value(:V3), do: 2
  def value(:V4), do: 3
  def value(:V5), do: 4

  @doc "Return the variant for an integer value, or `nil`."
  @spec from_value(integer()) :: t() | nil
  def from_value(0), do: :V1
  def from_value(1), do: :V2
  def from_value(2), do: :V3
  def from_value(3), do: :V4
  def from_value(4), do: :V5
  def from_value(_), do: nil

  @doc "List all variants in declared order."
  @spec all() :: [t()]
  def all, do: [:V1, :V2, :V3, :V4, :V5]

  @doc false
  def __flatbuf__(:underlying_type), do: :i16
end
