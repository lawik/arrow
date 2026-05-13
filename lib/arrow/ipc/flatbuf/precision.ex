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
  def __flatbuf__(:bit_flags?), do: false

  @doc false
  def __to_json__(atom) when is_atom(atom), do: Atom.to_string(atom)

  def __to_json__(int) when is_integer(int) do
    case from_value(int) do
      nil -> int
      atom -> Atom.to_string(atom)
    end
  end

  @doc false
  def __from_json__(name) when is_binary(name) do
    atom = String.to_atom(name)

    if atom in all(),
      do: atom,
      else: raise("unknown Arrow.Ipc.Flatbuf.Precision variant: " <> name)
  end

  def __from_json__(int) when is_integer(int) do
    from_value(int) ||
      raise("unknown Arrow.Ipc.Flatbuf.Precision value: " <> Integer.to_string(int))
  end
end
