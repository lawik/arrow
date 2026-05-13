defmodule Arrow.Logical do
  @moduledoc """
  Logical (null-aware) view of `Arrow.Array.*` columns.

  Two Arrow arrays are *logically equal* if, for each slot, both are
  null or both carry the same value. Byte-level differences that don't
  affect that observation — trailing junk bits in a validity bitmap,
  arbitrary content at null positions in a value buffer, two equivalent
  encodings of the same logical value — should not register as a
  difference.

  This module produces a canonical Elixir representation of each array:

      to_list(%Arrow.Array.Int32{...})   #=> [1, nil, 3, nil, 5]
      to_list(%Arrow.Array.Utf8{...})    #=> ["foo", nil, "bar"]
      to_list(%Arrow.Array.List{...})    #=> [[1, 2], [], [3, nil, 5]]
      to_list(%Arrow.Array.Struct{...})  #=> [[1, "a"], [2, nil], nil]

  Equality is then plain `to_list(a) == to_list(b)`. `equal?/2`,
  `arrays_equal?/2`, and `batches_equal?/2` are shortcuts.

  Caveats:

  - Field names are not preserved for `Struct` slots — children are
    represented positionally so two equivalent arrays compare equal
    without needing the schema. Use `to_list/1` plus the schema if you
    want field-named output.
  - `Float32`/`Float64` `NaN` slots do not compare equal to themselves,
    because `nil == nil` but `NaN != NaN` per IEEE-754. Callers
    comparing float data with NaNs should custom-compare.
  - `Decimal128` values are returned as their *unscaled* integer.
    Scale/precision are properties of the type, not the value.
  """

  alias Arrow.{Array, Buffer}

  @doc """
  Converts an `Arrow.Array.*` into a list of native Elixir values, with
  `nil` for null slots.
  """
  @spec to_list(Array.t()) :: [term()]
  def to_list(%Array.Null{length: n}), do: List.duplicate(nil, n)

  def to_list(%Array.Bool{} = a) do
    bools =
      a.values
      |> Buffer.unpack_bool_values(a.length)
      |> Enum.map(&(&1 == 1))

    apply_validity(a, bools)
  end

  def to_list(%Array.Int8{} = a), do: primitive_to_list(a, :int8)
  def to_list(%Array.Int16{} = a), do: primitive_to_list(a, :int16)
  def to_list(%Array.Int32{} = a), do: primitive_to_list(a, :int32)
  def to_list(%Array.Int64{} = a), do: primitive_to_list(a, :int64)
  def to_list(%Array.UInt8{} = a), do: primitive_to_list(a, :uint8)
  def to_list(%Array.UInt16{} = a), do: primitive_to_list(a, :uint16)
  def to_list(%Array.UInt32{} = a), do: primitive_to_list(a, :uint32)
  def to_list(%Array.UInt64{} = a), do: primitive_to_list(a, :uint64)
  def to_list(%Array.Float32{} = a), do: primitive_to_list(a, :float32)
  def to_list(%Array.Float64{} = a), do: primitive_to_list(a, :float64)
  def to_list(%Array.Date32{} = a), do: primitive_to_list(a, :int32)
  def to_list(%Array.Date64{} = a), do: primitive_to_list(a, :int64)

  def to_list(%Array.Timestamp{} = a), do: primitive_to_list(a, :int64)
  def to_list(%Array.Time32{} = a), do: primitive_to_list(a, :int32)
  def to_list(%Array.Time64{} = a), do: primitive_to_list(a, :int64)
  def to_list(%Array.Duration{} = a), do: primitive_to_list(a, :int64)

  def to_list(%Array.Decimal128{} = a) do
    values = unpack_decimal128(a.values, a.length)
    apply_validity(a, values)
  end

  def to_list(%Array.FixedSizeBinary{byte_width: w} = a) do
    chunks = for <<slot::binary-size(w) <- a.values>>, do: slot
    apply_validity(a, chunks)
  end

  def to_list(%Array.Utf8{} = a) do
    apply_validity(a, Buffer.slice_variable(a.offsets, a.values, a.length))
  end

  def to_list(%Array.Binary{} = a) do
    apply_validity(a, Buffer.slice_variable(a.offsets, a.values, a.length))
  end

  def to_list(%Array.List{} = a) do
    offsets = Buffer.unpack_int32_offsets(a.offsets, a.length)
    child = to_list(a.values)

    slices =
      offsets
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [from, to] -> Enum.slice(child, from, to - from) end)

    apply_validity(a, slices)
  end

  def to_list(%Array.FixedSizeList{list_size: sz} = a) do
    child = to_list(a.values)

    slices =
      for i <- 0..(a.length - 1)//1, do: Enum.slice(child, i * sz, sz)

    apply_validity(a, slices)
  end

  def to_list(%Array.Struct{children: children} = a) do
    rows = transpose(Enum.map(children, &to_list/1), a.length)
    apply_validity(a, rows)
  end

  def to_list(%Array.Map{values: %Array.Struct{children: [keys, values]}} = a) do
    offsets = Buffer.unpack_int32_offsets(a.offsets, a.length)
    key_list = to_list(keys)
    val_list = to_list(values)

    entries =
      offsets
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [from, to] ->
        Enum.zip(Enum.slice(key_list, from, to - from), Enum.slice(val_list, from, to - from))
      end)

    apply_validity(a, entries)
  end

  @doc "True iff two arrays are logically equal."
  @spec arrays_equal?(Array.t(), Array.t()) :: boolean()
  def arrays_equal?(a, b), do: a.__struct__ == b.__struct__ and to_list(a) == to_list(b)

  @doc "True iff two record batches are logically equal."
  @spec batches_equal?(Arrow.RecordBatch.t(), Arrow.RecordBatch.t()) :: boolean()
  def batches_equal?(%Arrow.RecordBatch{} = a, %Arrow.RecordBatch{} = b) do
    a.schema == b.schema and
      a.length == b.length and
      length(a.columns) == length(b.columns) and
      Enum.zip(a.columns, b.columns) |> Enum.all?(fn {x, y} -> arrays_equal?(x, y) end)
  end

  @doc "Same as `arrays_equal?/2`, kept generic for both array and batch inputs."
  @spec equal?(term(), term()) :: boolean()
  def equal?(%Arrow.RecordBatch{} = a, %Arrow.RecordBatch{} = b), do: batches_equal?(a, b)
  def equal?(a, b) when is_struct(a) and is_struct(b), do: arrays_equal?(a, b)

  ## ---------------------------------------------------------------------
  ## Internals
  ## ---------------------------------------------------------------------

  defp primitive_to_list(a, kind) do
    apply_validity(a, Buffer.unpack_primitive(a.values, kind, a.length))
  end

  defp apply_validity(%{length: 0}, _values), do: []

  defp apply_validity(%{validity: nil}, values), do: values

  defp apply_validity(a, values) do
    flags = Buffer.unpack_validity(a.validity, a.length)

    Enum.zip_with(flags, values, fn
      1, v -> v
      0, _ -> nil
    end)
  end

  defp unpack_decimal128(_binary, 0), do: []

  defp unpack_decimal128(binary, length) when length > 0 do
    do_unpack_decimal128(binary, length, [])
  end

  defp do_unpack_decimal128(_binary, 0, acc), do: Enum.reverse(acc)

  defp do_unpack_decimal128(<<v::little-signed-128, rest::binary>>, n, acc) do
    do_unpack_decimal128(rest, n - 1, [v | acc])
  end

  # Turn a list of N per-child columns (each of length M) into a list of M
  # per-row tuples-as-lists. Used by the Struct walker.
  defp transpose([], length), do: List.duplicate([], length)

  defp transpose(child_lists, _length) do
    child_lists
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end
end
