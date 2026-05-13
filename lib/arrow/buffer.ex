defmodule Arrow.Buffer do
  @moduledoc """
  Encoders and decoders between in-memory values and Arrow's raw buffer
  layout.

  The Arrow columnar format spec describes the per-type set of buffers (a
  validity bitmap, value buffer, optional offset buffer, etc.). This module
  packs and unpacks each of those buffers in isolation. The higher-level
  `Arrow.Array.*` structs hold the packed buffers directly, so the JSON
  reader/writer and (eventually) the IPC reader/writer can share this code.

  ## Conventions

  - All multi-byte integers and floats are little-endian.
  - Bitmaps (validity, Bool values) are LSB-first: slot `i` is bit `i mod 8`
    of byte `floor(i / 8)`, with the least-significant bit being slot 0.
  - For validity bitmaps, `1` means valid, `0` means null.
  - When a buffer is materialised for the IPC body, callers are expected to
    pad it to an 8-byte boundary using `pad_to_alignment/2`.
  """

  @type primitive_kind ::
          :int8
          | :int16
          | :int32
          | :int64
          | :uint8
          | :uint16
          | :uint32
          | :uint64
          | :float32
          | :float64

  @alignment 8

  ## ---------------------------------------------------------------------
  ## Validity bitmaps
  ## ---------------------------------------------------------------------

  @doc """
  Packs a list of `0 | 1 | true | false` flags into Arrow's LSB-first validity
  bitmap. Returns the bitmap *padded to a whole number of bytes* plus the null
  count.

      iex> {bitmap, null_count} = Arrow.Buffer.pack_validity([1, 0, 1, 1, 0])
      iex> null_count
      2
      iex> bitmap
      <<0b00001101::8>>
  """
  @spec pack_validity([0 | 1 | boolean()]) :: {binary(), non_neg_integer()}
  def pack_validity(flags) when is_list(flags) do
    {bits, null_count} = collect_validity(flags, 0)
    {pack_bits_lsb(bits), null_count}
  end

  defp collect_validity([], null_count), do: {[], null_count}

  defp collect_validity([h | t], null_count) do
    bit = to_bit(h)
    {rest, nc} = collect_validity(t, null_count + (1 - bit))
    {[bit | rest], nc}
  end

  defp to_bit(1), do: 1
  defp to_bit(0), do: 0
  defp to_bit(true), do: 1
  defp to_bit(false), do: 0

  @doc """
  Unpacks a validity bitmap into a list of `0 | 1` slots.

      iex> Arrow.Buffer.unpack_validity(<<0b00001101::8>>, 5)
      [1, 0, 1, 1, 0]
  """
  @spec unpack_validity(binary() | nil, non_neg_integer()) :: [0 | 1]
  def unpack_validity(nil, length), do: List.duplicate(1, length)
  def unpack_validity(bitmap, length), do: unpack_bits_lsb(bitmap, length)

  ## ---------------------------------------------------------------------
  ## Bool values (also a bitmap)
  ## ---------------------------------------------------------------------

  @doc """
  Packs a list of `0 | 1 | true | false` into a Bool *values* bitmap. Slots
  whose validity bit is 0 may carry any value; callers typically pass `0`.

      iex> Arrow.Buffer.pack_bool_values([true, false, true, true])
      <<0b00001101::8>>
  """
  @spec pack_bool_values([0 | 1 | boolean()]) :: binary()
  def pack_bool_values(values) do
    values
    |> Enum.map(&to_bit/1)
    |> pack_bits_lsb()
  end

  @doc """
  Unpacks a Bool values bitmap into a list of `0 | 1`.
  """
  @spec unpack_bool_values(binary(), non_neg_integer()) :: [0 | 1]
  def unpack_bool_values(bitmap, length), do: unpack_bits_lsb(bitmap, length)

  ## ---------------------------------------------------------------------
  ## Fixed-width primitive values
  ## ---------------------------------------------------------------------

  @doc """
  Packs a list of numeric values into a little-endian fixed-width buffer.

  `kind` is one of the atoms in `t:primitive_kind/0`. `:int64`-like atoms map
  to signed packing; `:uint*` to unsigned; `:float32` and `:float64` to IEEE
  floats. Null slots may carry any in-range placeholder (typically `0`).

      iex> Arrow.Buffer.pack_primitive([1, 2, 3], :int32)
      <<1::little-signed-32, 2::little-signed-32, 3::little-signed-32>>
  """
  @spec pack_primitive([number()], primitive_kind()) :: binary()
  def pack_primitive(values, :int8), do: for(v <- values, into: <<>>, do: <<v::little-signed-8>>)

  def pack_primitive(values, :int16),
    do: for(v <- values, into: <<>>, do: <<v::little-signed-16>>)

  def pack_primitive(values, :int32),
    do: for(v <- values, into: <<>>, do: <<v::little-signed-32>>)

  def pack_primitive(values, :int64),
    do: for(v <- values, into: <<>>, do: <<v::little-signed-64>>)

  def pack_primitive(values, :uint8),
    do: for(v <- values, into: <<>>, do: <<v::little-unsigned-8>>)

  def pack_primitive(values, :uint16),
    do: for(v <- values, into: <<>>, do: <<v::little-unsigned-16>>)

  def pack_primitive(values, :uint32),
    do: for(v <- values, into: <<>>, do: <<v::little-unsigned-32>>)

  def pack_primitive(values, :uint64),
    do: for(v <- values, into: <<>>, do: <<v::little-unsigned-64>>)

  def pack_primitive(values, :float32),
    do: for(v <- values, into: <<>>, do: <<v::little-float-32>>)

  def pack_primitive(values, :float64),
    do: for(v <- values, into: <<>>, do: <<v::little-float-64>>)

  @doc """
  Unpacks a fixed-width buffer into a list of values.

      iex> Arrow.Buffer.unpack_primitive(<<1::little-signed-32,
      ...>                                  2::little-signed-32,
      ...>                                  3::little-signed-32>>, :int32, 3)
      [1, 2, 3]
  """
  @spec unpack_primitive(binary(), primitive_kind(), non_neg_integer()) :: [number()]
  def unpack_primitive(<<>>, _kind, 0), do: []

  def unpack_primitive(binary, kind, length) when length > 0 do
    do_unpack_primitive(binary, kind, length, [])
  end

  defp do_unpack_primitive(_binary, _kind, 0, acc), do: Enum.reverse(acc)

  defp do_unpack_primitive(<<v::little-signed-8, rest::binary>>, :int8, n, acc),
    do: do_unpack_primitive(rest, :int8, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-signed-16, rest::binary>>, :int16, n, acc),
    do: do_unpack_primitive(rest, :int16, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-signed-32, rest::binary>>, :int32, n, acc),
    do: do_unpack_primitive(rest, :int32, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-signed-64, rest::binary>>, :int64, n, acc),
    do: do_unpack_primitive(rest, :int64, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-unsigned-8, rest::binary>>, :uint8, n, acc),
    do: do_unpack_primitive(rest, :uint8, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-unsigned-16, rest::binary>>, :uint16, n, acc),
    do: do_unpack_primitive(rest, :uint16, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-unsigned-32, rest::binary>>, :uint32, n, acc),
    do: do_unpack_primitive(rest, :uint32, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-unsigned-64, rest::binary>>, :uint64, n, acc),
    do: do_unpack_primitive(rest, :uint64, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-float-32, rest::binary>>, :float32, n, acc),
    do: do_unpack_primitive(rest, :float32, n - 1, [v | acc])

  defp do_unpack_primitive(<<v::little-float-64, rest::binary>>, :float64, n, acc),
    do: do_unpack_primitive(rest, :float64, n - 1, [v | acc])

  ## ---------------------------------------------------------------------
  ## Offset buffers (variable-binary / list)
  ## ---------------------------------------------------------------------

  @doc """
  Builds an `int32` offsets buffer from a list of per-slot byte lengths.

  The returned buffer has `length(byte_lengths) + 1` entries, starting at `0`
  and ending at the sum.

      iex> Arrow.Buffer.pack_int32_offsets([3, 2, 0])
      <<0::little-signed-32, 3::little-signed-32,
        5::little-signed-32, 5::little-signed-32>>
  """
  @spec pack_int32_offsets([non_neg_integer()]) :: binary()
  def pack_int32_offsets(lengths) do
    {offsets, _last} =
      Enum.flat_map_reduce(lengths, 0, fn len, acc ->
        next = acc + len
        {[next], next}
      end)

    [0 | offsets]
    |> Enum.map(&<<&1::little-signed-32>>)
    |> IO.iodata_to_binary()
  end

  @doc """
  Unpacks an `int32` offsets buffer of `length + 1` entries.
  """
  @spec unpack_int32_offsets(binary(), non_neg_integer()) :: [integer()]
  def unpack_int32_offsets(binary, length) when byte_size(binary) >= (length + 1) * 4 do
    do_unpack_int32_offsets(binary, length + 1, [])
  end

  defp do_unpack_int32_offsets(_binary, 0, acc), do: Enum.reverse(acc)

  defp do_unpack_int32_offsets(<<v::little-signed-32, rest::binary>>, n, acc) do
    do_unpack_int32_offsets(rest, n - 1, [v | acc])
  end

  @doc """
  Slices a variable-length value buffer using a list of `int32` offsets,
  returning one binary per slot.

      iex> offs = Arrow.Buffer.pack_int32_offsets([1, 2, 0, 3])
      iex> Arrow.Buffer.slice_variable(offs, "abcdef", 4)
      ["a", "bc", "", "def"]
  """
  @spec slice_variable(binary(), binary(), non_neg_integer()) :: [binary()]
  def slice_variable(offsets, values, length) do
    offsets
    |> unpack_int32_offsets(length)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [from, to] -> binary_part(values, from, to - from) end)
  end

  @doc """
  `int64` analogue of `pack_int32_offsets/1`, used by `LargeUtf8`,
  `LargeBinary`, and `LargeList`.
  """
  @spec pack_int64_offsets([non_neg_integer()]) :: binary()
  def pack_int64_offsets(lengths) do
    {offsets, _last} =
      Enum.flat_map_reduce(lengths, 0, fn len, acc ->
        next = acc + len
        {[next], next}
      end)

    [0 | offsets]
    |> Enum.map(&<<&1::little-signed-64>>)
    |> IO.iodata_to_binary()
  end

  @doc "Unpacks an `int64` offsets buffer of `length + 1` entries."
  @spec unpack_int64_offsets(binary(), non_neg_integer()) :: [integer()]
  def unpack_int64_offsets(binary, length) when byte_size(binary) >= (length + 1) * 8 do
    do_unpack_int64_offsets(binary, length + 1, [])
  end

  defp do_unpack_int64_offsets(_binary, 0, acc), do: Enum.reverse(acc)

  defp do_unpack_int64_offsets(<<v::little-signed-64, rest::binary>>, n, acc) do
    do_unpack_int64_offsets(rest, n - 1, [v | acc])
  end

  @doc """
  `int64` analogue of `slice_variable/3`, used by `LargeUtf8` and
  `LargeBinary`.
  """
  @spec slice_variable_large(binary(), binary(), non_neg_integer()) :: [binary()]
  def slice_variable_large(offsets, values, length) do
    offsets
    |> unpack_int64_offsets(length)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [from, to] -> binary_part(values, from, to - from) end)
  end

  ## ---------------------------------------------------------------------
  ## Alignment
  ## ---------------------------------------------------------------------

  @doc """
  Pads `binary` with zero bytes up to the next multiple of `alignment` bytes
  (default 8). Used at IPC body buffer boundaries.

      iex> Arrow.Buffer.pad_to_alignment(<<1, 2, 3>>)
      <<1, 2, 3, 0, 0, 0, 0, 0>>
  """
  @spec pad_to_alignment(binary(), pos_integer()) :: binary()
  def pad_to_alignment(binary, alignment \\ @alignment) do
    pad = padding_size(byte_size(binary), alignment)
    binary <> <<0::size(pad * 8)>>
  end

  @doc "Returns the number of pad bytes needed to reach the next alignment boundary."
  @spec padding_size(non_neg_integer(), pos_integer()) :: non_neg_integer()
  def padding_size(size, alignment \\ @alignment) do
    rem = rem(size, alignment)
    if rem == 0, do: 0, else: alignment - rem
  end

  ## ---------------------------------------------------------------------
  ## Internal bitmap helpers
  ## ---------------------------------------------------------------------

  defp pack_bits_lsb([]), do: <<>>

  defp pack_bits_lsb(bits) do
    bits
    |> Enum.chunk_every(8, 8, [0, 0, 0, 0, 0, 0, 0])
    |> Enum.map(&byte_from_lsb_bits/1)
    |> IO.iodata_to_binary()
  end

  defp byte_from_lsb_bits([b0, b1, b2, b3, b4, b5, b6, b7]) do
    <<b7::1, b6::1, b5::1, b4::1, b3::1, b2::1, b1::1, b0::1>>
  end

  defp unpack_bits_lsb(_binary, 0), do: []

  defp unpack_bits_lsb(binary, length) do
    do_unpack_bits(binary, length, [])
  end

  defp do_unpack_bits(_binary, 0, acc), do: Enum.reverse(acc)

  defp do_unpack_bits(<<byte::8, rest::binary>>, n, acc) when n >= 8 do
    do_unpack_bits(rest, n - 8, prepend_bits(byte, 0..7, acc))
  end

  defp do_unpack_bits(<<byte::8, _rest::binary>>, n, acc) when n > 0 do
    Enum.reverse(prepend_bits(byte, 0..(n - 1), acc))
  end

  defp prepend_bits(byte, range, acc) do
    Enum.reduce(range, acc, fn i, a ->
      [byte |> Bitwise.bsr(i) |> Bitwise.band(0x01) | a]
    end)
  end
end
