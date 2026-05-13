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
      else: raise("unknown Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis variant: " <> name)
  end

  def __from_json__(int) when is_integer(int) do
    from_value(int) ||
      raise(
        "unknown Arrow.Ipc.Flatbuf.SparseMatrixCompressedAxis value: " <> Integer.to_string(int)
      )
  end
end
