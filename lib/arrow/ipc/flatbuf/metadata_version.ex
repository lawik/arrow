defmodule Arrow.Ipc.Flatbuf.MetadataVersion do
  # Generated from FlatBuffers enum Arrow.Ipc.Flatbuf.MetadataVersion. Do not edit.
  @moduledoc false

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
      else: raise("unknown Arrow.Ipc.Flatbuf.MetadataVersion variant: " <> name)
  end

  def __from_json__(int) when is_integer(int) do
    from_value(int) ||
      raise("unknown Arrow.Ipc.Flatbuf.MetadataVersion value: " <> Integer.to_string(int))
  end
end
