defmodule Arrow.Ipc.Flatbuf.DateUnit do
  # Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.DateUnit. Do not edit.
  @moduledoc false

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
      else: raise("unknown Arrow.Ipc.Flatbuf.DateUnit variant: " <> name)
  end

  def __from_json__(int) when is_integer(int) do
    from_value(int) ||
      raise("unknown Arrow.Ipc.Flatbuf.DateUnit value: " <> Integer.to_string(int))
  end
end
