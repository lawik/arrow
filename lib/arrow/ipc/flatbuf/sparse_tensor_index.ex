defmodule Arrow.Ipc.Flatbuf.SparseTensorIndex do
  @moduledoc "Generated from FlatBuffers union Arrow.Ipc.Flatbuf.SparseTensorIndex. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

  @type t ::
          nil
          | {:SparseTensorIndexCOO, Arrow.Ipc.Flatbuf.SparseTensorIndexCOO.t()}
          | {:SparseMatrixIndexCSX, Arrow.Ipc.Flatbuf.SparseMatrixIndexCSX.t()}
          | {:SparseTensorIndexCSF, Arrow.Ipc.Flatbuf.SparseTensorIndexCSF.t()}

  @doc "Integer discriminator for a variant atom (0 for :NONE)."
  @spec discriminator(atom()) :: non_neg_integer()
  def discriminator(:NONE), do: 0
  def discriminator(:SparseTensorIndexCOO), do: 1
  def discriminator(:SparseMatrixIndexCSX), do: 2
  def discriminator(:SparseTensorIndexCSF), do: 3

  @doc "Variant atom for an integer discriminator."
  @spec variant_atom(non_neg_integer()) :: atom() | nil
  def variant_atom(0), do: :NONE
  def variant_atom(1), do: :SparseTensorIndexCOO
  def variant_atom(2), do: :SparseMatrixIndexCSX
  def variant_atom(3), do: :SparseTensorIndexCSF
  def variant_atom(_), do: nil

  @doc """
  Decode a union value at `abs_pos`, given its discriminator. The
  `abs_pos` is the absolute target of the uoffset_t the table field
  stored — i.e. for a table variant, the table position; for a
  string variant, the start of the u32 length; for a struct variant,
  the start of the inline struct bytes.
  """
  def decode_variant(_buf, 0, _abs_pos), do: nil

  def decode_variant(buf, 1, abs_pos),
    do: {:SparseTensorIndexCOO, Arrow.Ipc.Flatbuf.SparseTensorIndexCOO.decode_at(buf, abs_pos)}

  def decode_variant(buf, 2, abs_pos),
    do: {:SparseMatrixIndexCSX, Arrow.Ipc.Flatbuf.SparseMatrixIndexCSX.decode_at(buf, abs_pos)}

  def decode_variant(buf, 3, abs_pos),
    do: {:SparseTensorIndexCSF, Arrow.Ipc.Flatbuf.SparseTensorIndexCSF.decode_at(buf, abs_pos)}

  def decode_variant(_buf, disc, _abs_pos), do: {:unknown_variant, disc}

  @doc """
  Build a variant value into the builder. Returns `{builder, addr}`.
  For `:NONE`, returns `{builder, nil}`.
  """
  def build_variant(b, :NONE, _value), do: {b, nil}

  def build_variant(b, :SparseTensorIndexCOO, value),
    do: Arrow.Ipc.Flatbuf.SparseTensorIndexCOO.build(b, value)

  def build_variant(b, :SparseMatrixIndexCSX, value),
    do: Arrow.Ipc.Flatbuf.SparseMatrixIndexCSX.build(b, value)

  def build_variant(b, :SparseTensorIndexCSF, value),
    do: Arrow.Ipc.Flatbuf.SparseTensorIndexCSF.build(b, value)
end
