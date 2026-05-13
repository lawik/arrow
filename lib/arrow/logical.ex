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

  @typedoc "Dictionary registry: id → dictionary values array."
  @type dictionaries :: %{optional(non_neg_integer()) => Array.t()}

  @doc """
  Converts an `Arrow.Array.*` into a list of native Elixir values, with
  `nil` for null slots. Pass a `dictionaries` registry to resolve
  `Arrow.Array.Dictionary` columns to their dictionary values.
  """
  @spec to_list(Array.t(), dictionaries()) :: [term()]
  def to_list(array, dictionaries \\ %{})

  def to_list(%Array.Null{length: n}, _dicts), do: List.duplicate(nil, n)

  def to_list(%Array.Bool{} = a, _dicts) do
    bools =
      a.values
      |> Buffer.unpack_bool_values(a.length)
      |> Enum.map(&(&1 == 1))

    apply_validity(a, bools)
  end

  def to_list(%Array.Int8{} = a, _dicts), do: primitive_to_list(a, :int8)
  def to_list(%Array.Int16{} = a, _dicts), do: primitive_to_list(a, :int16)
  def to_list(%Array.Int32{} = a, _dicts), do: primitive_to_list(a, :int32)
  def to_list(%Array.Int64{} = a, _dicts), do: primitive_to_list(a, :int64)
  def to_list(%Array.UInt8{} = a, _dicts), do: primitive_to_list(a, :uint8)
  def to_list(%Array.UInt16{} = a, _dicts), do: primitive_to_list(a, :uint16)
  def to_list(%Array.UInt32{} = a, _dicts), do: primitive_to_list(a, :uint32)
  def to_list(%Array.UInt64{} = a, _dicts), do: primitive_to_list(a, :uint64)
  def to_list(%Array.Float32{} = a, _dicts), do: primitive_to_list(a, :float32)
  def to_list(%Array.Float64{} = a, _dicts), do: primitive_to_list(a, :float64)
  def to_list(%Array.Date32{} = a, _dicts), do: primitive_to_list(a, :int32)
  def to_list(%Array.Date64{} = a, _dicts), do: primitive_to_list(a, :int64)
  def to_list(%Array.Timestamp{} = a, _dicts), do: primitive_to_list(a, :int64)
  def to_list(%Array.Time32{} = a, _dicts), do: primitive_to_list(a, :int32)
  def to_list(%Array.Time64{} = a, _dicts), do: primitive_to_list(a, :int64)
  def to_list(%Array.Duration{} = a, _dicts), do: primitive_to_list(a, :int64)

  def to_list(%Array.IntervalYearMonth{} = a, _dicts) do
    apply_validity(a, Buffer.unpack_primitive(a.values, :int32, a.length))
  end

  def to_list(%Array.IntervalDayTime{} = a, _dicts) do
    apply_validity(a, unpack_day_time(a.values, a.length))
  end

  def to_list(%Array.IntervalMonthDayNano{} = a, _dicts) do
    apply_validity(a, unpack_month_day_nano(a.values, a.length))
  end

  def to_list(%Array.Decimal32{} = a, _dicts), do: apply_validity(a, decimal_values(a, 32))
  def to_list(%Array.Decimal64{} = a, _dicts), do: apply_validity(a, decimal_values(a, 64))
  def to_list(%Array.Decimal128{} = a, _dicts), do: apply_validity(a, decimal_values(a, 128))
  def to_list(%Array.Decimal256{} = a, _dicts), do: apply_validity(a, decimal_values(a, 256))

  def to_list(%Array.FixedSizeBinary{byte_width: w} = a, _dicts) do
    chunks = for <<slot::binary-size(w) <- a.values>>, do: slot
    apply_validity(a, chunks)
  end

  def to_list(%Array.Utf8{} = a, _dicts) do
    apply_validity(a, Buffer.slice_variable(a.offsets, a.values, a.length))
  end

  def to_list(%Array.Binary{} = a, _dicts) do
    apply_validity(a, Buffer.slice_variable(a.offsets, a.values, a.length))
  end

  def to_list(%Array.List{} = a, dicts) do
    offsets = Buffer.unpack_int32_offsets(a.offsets, a.length)
    child = to_list(a.values, dicts)

    slices =
      offsets
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [from, to] -> Enum.slice(child, from, to - from) end)

    apply_validity(a, slices)
  end

  def to_list(%Array.LargeUtf8{} = a, _dicts) do
    apply_validity(a, Buffer.slice_variable_large(a.offsets, a.values, a.length))
  end

  def to_list(%Array.LargeBinary{} = a, _dicts) do
    apply_validity(a, Buffer.slice_variable_large(a.offsets, a.values, a.length))
  end

  def to_list(%Array.LargeList{} = a, dicts) do
    offsets = Buffer.unpack_int64_offsets(a.offsets, a.length)
    child = to_list(a.values, dicts)

    slices =
      offsets
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [from, to] -> Enum.slice(child, from, to - from) end)

    apply_validity(a, slices)
  end

  def to_list(%Array.FixedSizeList{list_size: sz} = a, dicts) do
    child = to_list(a.values, dicts)

    slices =
      for i <- 0..(a.length - 1)//1, do: Enum.slice(child, i * sz, sz)

    apply_validity(a, slices)
  end

  def to_list(%Array.Struct{children: children} = a, dicts) do
    rows = transpose(Enum.map(children, &to_list(&1, dicts)), a.length)
    apply_validity(a, rows)
  end

  def to_list(%Array.Map{values: %Array.Struct{children: [keys, values]}} = a, dicts) do
    offsets = Buffer.unpack_int32_offsets(a.offsets, a.length)
    key_list = to_list(keys, dicts)
    val_list = to_list(values, dicts)

    entries =
      offsets
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [from, to] ->
        Enum.zip(Enum.slice(key_list, from, to - from), Enum.slice(val_list, from, to - from))
      end)

    apply_validity(a, entries)
  end

  def to_list(%Array.Dictionary{dictionary_id: id, indices: indices}, dicts) do
    dict_array =
      Map.get(dicts, id) ||
        raise(ArgumentError, "no dictionary registered for id #{id}")

    dict_values = to_list(dict_array, dicts)
    index_list = to_list(indices, dicts)

    Enum.map(index_list, fn
      nil -> nil
      i -> Enum.at(dict_values, i)
    end)
  end

  @doc "True iff two arrays are logically equal, given their dictionary registries."
  @spec arrays_equal?(Array.t(), Array.t(), dictionaries(), dictionaries()) :: boolean()
  def arrays_equal?(a, b, dicts_a \\ %{}, dicts_b \\ %{}) do
    a.__struct__ == b.__struct__ and to_list(a, dicts_a) == to_list(b, dicts_b)
  end

  @doc """
  True iff two record batches are logically equal.

  Schemas are compared via `schemas_equivalent?/2`, which treats
  dictionary IDs as opaque labels — producers may assign different IDs
  to semantically-identical dictionaries. The optional registries are
  used to resolve `Arrow.Array.Dictionary` columns to their values
  during comparison.
  """
  @spec batches_equal?(
          Arrow.RecordBatch.t(),
          Arrow.RecordBatch.t(),
          dictionaries(),
          dictionaries()
        ) :: boolean()
  def batches_equal?(
        %Arrow.RecordBatch{} = a,
        %Arrow.RecordBatch{} = b,
        dicts_a \\ %{},
        dicts_b \\ %{}
      ) do
    schemas_equivalent?(a.schema, b.schema) and
      a.length == b.length and
      length(a.columns) == length(b.columns) and
      a.columns
      |> Enum.zip(b.columns)
      |> Enum.all?(fn {x, y} -> arrays_equal?(x, y, dicts_a, dicts_b) end)
  end

  @doc """
  True iff a complete payload (schema + dictionaries + batches) is
  logically equivalent to another. Tolerates differences in dictionary
  ID assignment between the two sides: two payloads describing the
  same data with different dictionary IDs compare equal.
  """
  @spec payloads_equivalent?(
          %{schema: Arrow.Schema.t(), dictionaries: dictionaries(), batches: [Arrow.RecordBatch.t()]},
          %{schema: Arrow.Schema.t(), dictionaries: dictionaries(), batches: [Arrow.RecordBatch.t()]}
        ) :: boolean()
  def payloads_equivalent?(
        %{schema: sa, dictionaries: da, batches: ba},
        %{schema: sb, dictionaries: db, batches: bb}
      ) do
    schemas_equivalent?(sa, sb) and
      length(ba) == length(bb) and
      dictionaries_equivalent_via_schemas?(sa, da, sb, db) and
      Enum.zip(ba, bb)
      |> Enum.all?(fn {x, y} -> batches_equal?(x, y, da, db) end)
  end

  @doc """
  True iff two schemas describe the same logical shape.

  Identical to `==` except that `Arrow.Field.dictionary.id` is treated
  as an opaque label: two fields where one has `dictionary.id = 0` and
  the other has `dictionary.id = 7` are still equivalent provided the
  rest of their dictionary annotation (index_type, is_ordered) and
  surrounding field structure agrees.

  Use `==` instead if you need strict structural equality.
  """
  @spec schemas_equivalent?(Arrow.Schema.t(), Arrow.Schema.t()) :: boolean()
  def schemas_equivalent?(%Arrow.Schema{} = a, %Arrow.Schema{} = b) do
    fields_equivalent?(a.fields, b.fields) and a.metadata == b.metadata
  end

  @doc """
  True iff two dictionary registries are logically equivalent, given
  the schemas referring to them.

  Walks the field tree of both schemas in parallel; for every
  dict-encoded field pair, looks up the corresponding dictionary in
  each registry by the *field's* ID, then compares the dictionary
  arrays logically. ID values themselves are never compared directly.
  """
  @spec dictionaries_equivalent_via_schemas?(
          Arrow.Schema.t(),
          dictionaries(),
          Arrow.Schema.t(),
          dictionaries()
        ) :: boolean()
  def dictionaries_equivalent_via_schemas?(%Arrow.Schema{} = sa, da, %Arrow.Schema{} = sb, db) do
    sa.fields
    |> Enum.zip(sb.fields)
    |> Enum.flat_map(fn {a, b} -> field_dict_id_pairs(a, b) end)
    |> Enum.all?(fn {id_a, id_b} ->
      case {Map.get(da, id_a), Map.get(db, id_b)} do
        {nil, _} -> false
        {_, nil} -> false
        {arr_a, arr_b} -> arrays_equal?(arr_a, arr_b, da, db)
      end
    end)
  end

  @doc "Same as `arrays_equal?/2`, kept generic for both array and batch inputs."
  @spec equal?(term(), term()) :: boolean()
  def equal?(%Arrow.RecordBatch{} = a, %Arrow.RecordBatch{} = b), do: batches_equal?(a, b)
  def equal?(a, b) when is_struct(a) and is_struct(b), do: arrays_equal?(a, b)

  ## ---------------------------------------------------------------------
  ## Schema walking helpers
  ## ---------------------------------------------------------------------

  defp fields_equivalent?(list_a, list_b) when length(list_a) == length(list_b) do
    list_a
    |> Enum.zip(list_b)
    |> Enum.all?(fn {a, b} -> field_equivalent?(a, b) end)
  end

  defp fields_equivalent?(_, _), do: false

  defp field_equivalent?(%Arrow.Field{} = a, %Arrow.Field{} = b) do
    a.name == b.name and
      a.type == b.type and
      a.nullable == b.nullable and
      a.metadata == b.metadata and
      fields_equivalent?(a.children, b.children) and
      dictionary_encoding_equivalent?(a.dictionary, b.dictionary)
  end

  defp dictionary_encoding_equivalent?(nil, nil), do: true

  defp dictionary_encoding_equivalent?(
         %Arrow.Type.DictionaryEncoding{} = a,
         %Arrow.Type.DictionaryEncoding{} = b
       ) do
    a.index_type == b.index_type and a.is_ordered == b.is_ordered
  end

  defp dictionary_encoding_equivalent?(_, _), do: false

  # Returns a flat list of {id_in_a, id_in_b} for every dict-encoded
  # field pair across the parallel field trees.
  defp field_dict_id_pairs(%Arrow.Field{dictionary: nil} = a, %Arrow.Field{dictionary: nil} = b) do
    a.children
    |> Enum.zip(b.children)
    |> Enum.flat_map(fn {x, y} -> field_dict_id_pairs(x, y) end)
  end

  defp field_dict_id_pairs(
         %Arrow.Field{dictionary: %{id: ida}} = a,
         %Arrow.Field{dictionary: %{id: idb}} = b
       ) do
    [
      {ida, idb}
      | a.children
        |> Enum.zip(b.children)
        |> Enum.flat_map(fn {x, y} -> field_dict_id_pairs(x, y) end)
    ]
  end

  defp field_dict_id_pairs(_, _), do: []

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

  defp decimal_values(a, bw), do: unpack_decimal(a.values, a.length, bw)

  defp unpack_decimal(_binary, 0, _bw), do: []

  defp unpack_decimal(binary, length, bw) when length > 0 do
    do_unpack_decimal(binary, length, bw, [])
  end

  defp do_unpack_decimal(_binary, 0, _bw, acc), do: Enum.reverse(acc)

  defp do_unpack_decimal(<<v::little-signed-32, rest::binary>>, n, 32, acc),
    do: do_unpack_decimal(rest, n - 1, 32, [v | acc])

  defp do_unpack_decimal(<<v::little-signed-64, rest::binary>>, n, 64, acc),
    do: do_unpack_decimal(rest, n - 1, 64, [v | acc])

  defp do_unpack_decimal(<<v::little-signed-128, rest::binary>>, n, 128, acc),
    do: do_unpack_decimal(rest, n - 1, 128, [v | acc])

  defp do_unpack_decimal(<<v::little-signed-256, rest::binary>>, n, 256, acc),
    do: do_unpack_decimal(rest, n - 1, 256, [v | acc])

  defp unpack_day_time(_binary, 0), do: []

  defp unpack_day_time(binary, length) when length > 0 do
    do_unpack_day_time(binary, length, [])
  end

  defp do_unpack_day_time(_binary, 0, acc), do: Enum.reverse(acc)

  defp do_unpack_day_time(
         <<d::little-signed-32, m::little-signed-32, rest::binary>>,
         n,
         acc
       ),
       do: do_unpack_day_time(rest, n - 1, [%{days: d, milliseconds: m} | acc])

  defp unpack_month_day_nano(_binary, 0), do: []

  defp unpack_month_day_nano(binary, length) when length > 0 do
    do_unpack_month_day_nano(binary, length, [])
  end

  defp do_unpack_month_day_nano(_binary, 0, acc), do: Enum.reverse(acc)

  defp do_unpack_month_day_nano(
         <<m::little-signed-32, d::little-signed-32, n::little-signed-64, rest::binary>>,
         count,
         acc
       ),
       do:
         do_unpack_month_day_nano(rest, count - 1, [
           %{months: m, days: d, nanoseconds: n} | acc
         ])

  # Turn a list of N per-child columns (each of length M) into a list of M
  # per-row tuples-as-lists. Used by the Struct walker.
  defp transpose([], length), do: List.duplicate([], length)

  defp transpose(child_lists, _length) do
    child_lists
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end
end
