defmodule Arrow.Ipc.Flatbuf.MessageHeader do
  @moduledoc "Generated from FlatBuffers union Arrow.Ipc.Flatbuf.MessageHeader. Do not edit."

  @type t ::
          nil
          | {:Schema, Arrow.Ipc.Flatbuf.Schema.t()}
          | {:DictionaryBatch, Arrow.Ipc.Flatbuf.DictionaryBatch.t()}
          | {:RecordBatch, Arrow.Ipc.Flatbuf.RecordBatch.t()}
          | {:Tensor, Arrow.Ipc.Flatbuf.Tensor.t()}
          | {:SparseTensor, Arrow.Ipc.Flatbuf.SparseTensor.t()}

  @doc "Integer discriminator for a variant atom (0 for :NONE)."
  @spec discriminator(atom()) :: non_neg_integer()
  def discriminator(:NONE), do: 0
  def discriminator(:Schema), do: 1
  def discriminator(:DictionaryBatch), do: 2
  def discriminator(:RecordBatch), do: 3
  def discriminator(:Tensor), do: 4
  def discriminator(:SparseTensor), do: 5

  @doc "Variant atom for an integer discriminator."
  @spec variant_atom(non_neg_integer()) :: atom() | nil
  def variant_atom(0), do: :NONE
  def variant_atom(1), do: :Schema
  def variant_atom(2), do: :DictionaryBatch
  def variant_atom(3), do: :RecordBatch
  def variant_atom(4), do: :Tensor
  def variant_atom(5), do: :SparseTensor
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
    do: {:Schema, Arrow.Ipc.Flatbuf.Schema.decode_at(buf, abs_pos)}

  def decode_variant(buf, 2, abs_pos),
    do: {:DictionaryBatch, Arrow.Ipc.Flatbuf.DictionaryBatch.decode_at(buf, abs_pos)}

  def decode_variant(buf, 3, abs_pos),
    do: {:RecordBatch, Arrow.Ipc.Flatbuf.RecordBatch.decode_at(buf, abs_pos)}

  def decode_variant(buf, 4, abs_pos),
    do: {:Tensor, Arrow.Ipc.Flatbuf.Tensor.decode_at(buf, abs_pos)}

  def decode_variant(buf, 5, abs_pos),
    do: {:SparseTensor, Arrow.Ipc.Flatbuf.SparseTensor.decode_at(buf, abs_pos)}

  def decode_variant(_buf, disc, _abs_pos), do: {:unknown_variant, disc}

  @doc """
  Build a variant value into the builder. Returns `{builder, addr}`.
  For `:NONE`, returns `{builder, nil}`.
  """
  def build_variant(b, :NONE, _value), do: {b, nil}
  def build_variant(b, :Schema, value), do: Arrow.Ipc.Flatbuf.Schema.build(b, value)

  def build_variant(b, :DictionaryBatch, value),
    do: Arrow.Ipc.Flatbuf.DictionaryBatch.build(b, value)

  def build_variant(b, :RecordBatch, value), do: Arrow.Ipc.Flatbuf.RecordBatch.build(b, value)
  def build_variant(b, :Tensor, value), do: Arrow.Ipc.Flatbuf.Tensor.build(b, value)
  def build_variant(b, :SparseTensor, value), do: Arrow.Ipc.Flatbuf.SparseTensor.build(b, value)

  # JSON helpers — used by table codegen for the paired `_type` and
  # value keys flatc emits.

  @doc false
  # flatc emits the union `_type` key as `"NONE"` (not omitted) when
  # the discriminator is 0, so match that to keep JSON comparisons
  # aligned. The value side stays nil and gets dropped by the
  # caller's `Map.reject`.
  def __to_json_type__(nil), do: "NONE"
  def __to_json_type__({variant, _value}), do: Atom.to_string(variant)

  @doc false
  def __to_json_value__(nil), do: nil
  def __to_json_value__({:Schema, value}), do: Arrow.Ipc.Flatbuf.Schema.__to_json_map__(value)

  def __to_json_value__({:DictionaryBatch, value}),
    do: Arrow.Ipc.Flatbuf.DictionaryBatch.__to_json_map__(value)

  def __to_json_value__({:RecordBatch, value}),
    do: Arrow.Ipc.Flatbuf.RecordBatch.__to_json_map__(value)

  def __to_json_value__({:Tensor, value}), do: Arrow.Ipc.Flatbuf.Tensor.__to_json_map__(value)

  def __to_json_value__({:SparseTensor, value}),
    do: Arrow.Ipc.Flatbuf.SparseTensor.__to_json_map__(value)

  @doc false
  def __from_json__(nil, _value), do: nil
  def __from_json__("NONE", _value), do: nil

  def __from_json__("Schema", value),
    do: {:Schema, Arrow.Ipc.Flatbuf.Schema.__from_json_map__(value)}

  def __from_json__("DictionaryBatch", value),
    do: {:DictionaryBatch, Arrow.Ipc.Flatbuf.DictionaryBatch.__from_json_map__(value)}

  def __from_json__("RecordBatch", value),
    do: {:RecordBatch, Arrow.Ipc.Flatbuf.RecordBatch.__from_json_map__(value)}

  def __from_json__("Tensor", value),
    do: {:Tensor, Arrow.Ipc.Flatbuf.Tensor.__from_json_map__(value)}

  def __from_json__("SparseTensor", value),
    do: {:SparseTensor, Arrow.Ipc.Flatbuf.SparseTensor.__from_json_map__(value)}

  @doc false
  def __verify_variant__(_buf, 0, _abs_pos, _depth), do: :ok

  def __verify_variant__(buf, 1, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Schema.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 2, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.DictionaryBatch.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 3, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.RecordBatch.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 4, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Tensor.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 5, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.SparseTensor.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(_buf, disc, _abs_pos, _depth),
    do: {:error, {:unknown_union_variant, disc}}
end
