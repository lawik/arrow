defmodule Arrow.Ipc.Body do
  @moduledoc """
  Encodes and decodes the body bytes of an Arrow IPC RecordBatch.

  An Arrow IPC body is the concatenation of every column's raw buffers
  (`validity`, `offsets`, `values`, ...) in depth-first preorder, each
  padded to an 8-byte boundary. The associated RecordBatch metadata
  describes the body as two parallel flat lists:

  - `nodes` — one `FieldNode` per *physical* array (each nested array
    contributes its own node), carrying `length` and `null_count`.
  - `buffers` — one `Buffer` per *physical* buffer, carrying the byte
    `offset` into the body and the byte `length`.

  This module owns the walking order, the per-type buffer set, and the
  alignment padding. It does not own the FlatBuffers encoding of those
  descriptors — that's `Arrow.Ipc.Metadata`.

  ## Per-type buffer layout

      Null              0 buffers, 1 node
      Bool              [validity, values]  (both bitmaps)
      Int*/UInt*/Float* [validity, values]
      Date32/Date64     [validity, values]
      Timestamp         [validity, values]
      Time32/Time64     [validity, values]
      Duration          [validity, values]
      Decimal128        [validity, values]
      FixedSizeBinary   [validity, values]
      Utf8/Binary       [validity, offsets, values]
      List              [validity, offsets]  + 1 child array
      FixedSizeList     [validity]           + 1 child array
      Struct            [validity]           + N child arrays
      Map               [validity, offsets]  + 1 entries struct array
  """

  alias Arrow.{Array, Field, RecordBatch, Schema}
  alias Arrow.Buffer, as: Buf

  @alignment 8

  @typedoc "FieldNode descriptor — a per-array stats entry."
  @type node_desc :: %{length: non_neg_integer(), null_count: non_neg_integer()}

  @typedoc "Buffer descriptor — a per-buffer (offset, length) into the body."
  @type buffer_desc :: %{offset: non_neg_integer(), length: non_neg_integer()}

  @typedoc "The result of `encode/1`: descriptors plus the concatenated body bytes."
  @type encoded :: %{
          length: non_neg_integer(),
          nodes: [node_desc()],
          buffers: [buffer_desc()],
          body: binary()
        }

  @doc """
  Walks `batch`'s columns and produces the body bytes plus the parallel
  `nodes` and `buffers` lists.
  """
  @spec encode(RecordBatch.t()) :: encoded()
  def encode(%RecordBatch{schema: schema, length: row_count, columns: columns}) do
    if length(columns) != length(schema.fields) do
      raise ArgumentError, "column count does not match schema field count"
    end

    {nodes_rev, bufs_rev, body_iolist, _total} =
      Enum.reduce(columns, {[], [], [], 0}, fn array, acc ->
        encode_array(array, acc)
      end)

    %{
      length: row_count,
      nodes: Enum.reverse(nodes_rev),
      buffers: Enum.reverse(bufs_rev),
      body: IO.iodata_to_binary(body_iolist)
    }
  end

  @doc """
  Encodes a single array's buffers (no surrounding RecordBatch). Used by
  the IPC layer to produce a DictionaryBatch body.
  """
  @spec encode_array(Arrow.Array.t()) ::
          %{nodes: [node_desc()], buffers: [buffer_desc()], body: binary()}
  def encode_array(array) when is_struct(array) do
    {nodes_rev, bufs_rev, body_iolist, _total} = encode_array(array, {[], [], [], 0})

    %{
      nodes: Enum.reverse(nodes_rev),
      buffers: Enum.reverse(bufs_rev),
      body: IO.iodata_to_binary(body_iolist)
    }
  end

  @doc """
  Decodes a single array out of pre-extracted descriptors + body bytes.
  Used by the IPC layer for DictionaryBatch decoding.
  """
  @spec decode_array_buffers(Field.t(), [node_desc()], [buffer_desc()], binary()) ::
          Arrow.Array.t()
  def decode_array_buffers(%Field{} = field, nodes, buffers, body) do
    {array, [], []} = decode_array(field, nodes, buffers, body)
    array
  end

  @doc """
  Reverses `encode/1`: takes the schema, row count, and the descriptor +
  body produced by an encoder (ours or another implementation), and
  reconstructs the `RecordBatch`.
  """
  @spec decode(Schema.t(), non_neg_integer(), [node_desc()], [buffer_desc()], binary()) ::
          RecordBatch.t()
  def decode(%Schema{fields: fields} = schema, length, nodes, buffers, body) do
    {columns, [], []} =
      Enum.reduce(fields, {[], nodes, buffers}, fn field, {acc, ns, bs} ->
        {array, ns2, bs2} = decode_array(field, ns, bs, body)
        {[array | acc], ns2, bs2}
      end)

    %RecordBatch{
      schema: schema,
      length: length,
      columns: Enum.reverse(columns)
    }
  end

  ## ---------------------------------------------------------------------
  ## Encode walk
  ## ---------------------------------------------------------------------

  defp encode_array(%Array.Null{length: n}, {ns, bs, body, off}) do
    {[node(n, n) | ns], bs, body, off}
  end

  defp encode_array(%Array.Dictionary{indices: indices}, acc) do
    # The body for a dictionary-encoded column is just the indices.
    # The dictionary values travel separately as a DictionaryBatch.
    encode_array(indices, acc)
  end

  defp encode_array(%Array.Bool{} = a, acc) do
    acc
    |> push_node(a.length, a.null_count)
    |> push_buffer(a.validity, bitmap_size(a.length))
    |> push_buffer(a.values, bitmap_size(a.length))
  end

  defp encode_array(%mod{} = a, acc)
       when mod in [
              Array.Int8,
              Array.Int16,
              Array.Int32,
              Array.Int64,
              Array.UInt8,
              Array.UInt16,
              Array.UInt32,
              Array.UInt64,
              Array.Float32,
              Array.Float64,
              Array.Date32,
              Array.Date64,
              Array.Timestamp,
              Array.Duration
            ] do
    acc
    |> push_node(a.length, a.null_count)
    |> push_buffer(a.validity, bitmap_size(a.length))
    |> push_buffer(a.values, byte_size(a.values))
  end

  defp encode_array(%Array.Time32{} = a, acc) do
    acc
    |> push_node(a.length, a.null_count)
    |> push_buffer(a.validity, bitmap_size(a.length))
    |> push_buffer(a.values, byte_size(a.values))
  end

  defp encode_array(%Array.Time64{} = a, acc) do
    acc
    |> push_node(a.length, a.null_count)
    |> push_buffer(a.validity, bitmap_size(a.length))
    |> push_buffer(a.values, byte_size(a.values))
  end

  defp encode_array(%mod{} = a, acc)
       when mod in [Array.Decimal32, Array.Decimal64, Array.Decimal128, Array.Decimal256] do
    acc
    |> push_node(a.length, a.null_count)
    |> push_buffer(a.validity, bitmap_size(a.length))
    |> push_buffer(a.values, byte_size(a.values))
  end

  defp encode_array(%Array.FixedSizeBinary{} = a, acc) do
    acc
    |> push_node(a.length, a.null_count)
    |> push_buffer(a.validity, bitmap_size(a.length))
    |> push_buffer(a.values, byte_size(a.values))
  end

  defp encode_array(%Array.Utf8{} = a, acc) do
    acc
    |> push_node(a.length, a.null_count)
    |> push_buffer(a.validity, bitmap_size(a.length))
    |> push_buffer(a.offsets, byte_size(a.offsets))
    |> push_buffer(a.values, byte_size(a.values))
  end

  defp encode_array(%Array.Binary{} = a, acc) do
    acc
    |> push_node(a.length, a.null_count)
    |> push_buffer(a.validity, bitmap_size(a.length))
    |> push_buffer(a.offsets, byte_size(a.offsets))
    |> push_buffer(a.values, byte_size(a.values))
  end

  defp encode_array(%Array.List{} = a, acc) do
    encode_array(
      a.values,
      acc
      |> push_node(a.length, a.null_count)
      |> push_buffer(a.validity, bitmap_size(a.length))
      |> push_buffer(a.offsets, byte_size(a.offsets))
    )
  end

  defp encode_array(%Array.FixedSizeList{} = a, acc) do
    encode_array(
      a.values,
      acc
      |> push_node(a.length, a.null_count)
      |> push_buffer(a.validity, bitmap_size(a.length))
    )
  end

  defp encode_array(%Array.Struct{} = a, acc) do
    encode_children(
      a.children,
      acc
      |> push_node(a.length, a.null_count)
      |> push_buffer(a.validity, bitmap_size(a.length))
    )
  end

  defp encode_array(%Array.Map{} = a, acc) do
    encode_array(
      a.values,
      acc
      |> push_node(a.length, a.null_count)
      |> push_buffer(a.validity, bitmap_size(a.length))
      |> push_buffer(a.offsets, byte_size(a.offsets))
    )
  end

  defp encode_children([child | rest], acc) do
    encode_children(rest, encode_array(child, acc))
  end

  defp encode_children([], acc), do: acc

  ## ---------------------------------------------------------------------
  ## Encode helpers
  ## ---------------------------------------------------------------------

  defp node(length, null_count), do: %{length: length, null_count: null_count}

  defp push_node({ns, bs, body, off}, length, null_count) do
    {[node(length, null_count) | ns], bs, body, off}
  end

  defp push_buffer({ns, bs, body, off}, nil, _len) do
    # Omitted buffer (typically validity for null_count = 0). The Arrow spec
    # still requires an entry in the buffers vector; record it as a zero-length
    # buffer at the current offset.
    {ns, [%{offset: off, length: 0} | bs], body, off}
  end

  defp push_buffer({ns, bs, body, off}, bin, len) do
    pad = padding(len)
    new_body = [body, bin, <<0::size(pad * 8)>>]
    {ns, [%{offset: off, length: len} | bs], new_body, off + len + pad}
  end

  defp bitmap_size(length), do: div(length + 7, 8)

  defp padding(len) do
    case rem(len, @alignment) do
      0 -> 0
      r -> @alignment - r
    end
  end

  ## ---------------------------------------------------------------------
  ## Decode walk
  ## ---------------------------------------------------------------------

  defp decode_array(
         %Field{dictionary: %Arrow.Type.DictionaryEncoding{id: id, index_type: idx_type}},
         nodes,
         buffers,
         body
       ) do
    # Decode using the field's index type, then wrap in Dictionary.
    # The field passed to the inner decoder must NOT carry the
    # dictionary annotation, or we'd recurse forever.
    inner_field = %Field{
      name: "indices",
      type: idx_type,
      nullable: true,
      children: [],
      metadata: %{}
    }

    {indices, ns2, bs2} = decode_array(inner_field, nodes, buffers, body)
    {%Array.Dictionary{dictionary_id: id, indices: indices}, ns2, bs2}
  end

  defp decode_array(%Field{type: %Arrow.Type.Null{}}, [n | ns], bs, _body) do
    {%Array.Null{length: n.length}, ns, bs}
  end

  defp decode_array(%Field{type: %Arrow.Type.Bool{}}, [n | ns], [v, d | bs], body) do
    {%Array.Bool{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_bitmap(body, d, n.length)
     }, ns, bs}
  end

  defp decode_array(%Field{type: %Arrow.Type.Int{} = t}, [n | ns], [v, d | bs], body) do
    {struct!(primitive_array_mod(t), %{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }), ns, bs}
  end

  defp decode_array(%Field{type: %Arrow.Type.FloatingPoint{} = t}, [n | ns], [v, d | bs], body) do
    {struct!(primitive_array_mod(t), %{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }), ns, bs}
  end

  defp decode_array(%Field{type: %Arrow.Type.Date{unit: :day}}, [n | ns], [v, d | bs], body) do
    {%Array.Date32{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.Date{unit: :millisecond}},
         [n | ns],
         [v, d | bs],
         body
       ) do
    {%Array.Date64{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.Timestamp{unit: u, timezone: tz}},
         [n | ns],
         [v, d | bs],
         body
       ) do
    {%Array.Timestamp{
       unit: u,
       timezone: tz,
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.Time{bit_width: 32, unit: u}},
         [n | ns],
         [v, d | bs],
         body
       ) do
    {%Array.Time32{
       unit: u,
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.Time{bit_width: 64, unit: u}},
         [n | ns],
         [v, d | bs],
         body
       ) do
    {%Array.Time64{
       unit: u,
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(%Field{type: %Arrow.Type.Duration{unit: u}}, [n | ns], [v, d | bs], body) do
    {%Array.Duration{
       unit: u,
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.Decimal{bit_width: bw, precision: p, scale: s}},
         [n | ns],
         [v, d | bs],
         body
       )
       when bw in [32, 64, 128, 256] do
    {struct!(decimal_array_mod(bw), %{
       precision: p,
       scale: s,
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }), ns, bs}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.FixedSizeBinary{byte_width: bw}},
         [n | ns],
         [v, d | bs],
         body
       ) do
    {%Array.FixedSizeBinary{
       byte_width: bw,
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(%Field{type: %Arrow.Type.Utf8{}}, [n | ns], [v, o, d | bs], body) do
    {%Array.Utf8{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       offsets: take_slice(body, o),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(%Field{type: %Arrow.Type.Binary{}}, [n | ns], [v, o, d | bs], body) do
    {%Array.Binary{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       offsets: take_slice(body, o),
       values: take_slice(body, d)
     }, ns, bs}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.List{}, children: [child_field]},
         [n | ns],
         [v, o | bs],
         body
       ) do
    {child_array, ns2, bs2} = decode_array(child_field, ns, bs, body)

    {%Array.List{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       offsets: take_slice(body, o),
       values: child_array
     }, ns2, bs2}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.FixedSizeList{list_size: sz}, children: [child_field]},
         [n | ns],
         [v | bs],
         body
       ) do
    {child_array, ns2, bs2} = decode_array(child_field, ns, bs, body)

    {%Array.FixedSizeList{
       list_size: sz,
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       values: child_array
     }, ns2, bs2}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.Struct{}, children: child_fields},
         [n | ns],
         [v | bs],
         body
       ) do
    {children_rev, ns2, bs2} =
      Enum.reduce(child_fields, {[], ns, bs}, fn cf, {acc, nns, bbs} ->
        {child, nns2, bbs2} = decode_array(cf, nns, bbs, body)
        {[child | acc], nns2, bbs2}
      end)

    {%Array.Struct{
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       children: Enum.reverse(children_rev)
     }, ns2, bs2}
  end

  defp decode_array(
         %Field{type: %Arrow.Type.Map{keys_sorted: ks}, children: [entries_field]},
         [n | ns],
         [v, o | bs],
         body
       ) do
    {entries_array, ns2, bs2} = decode_array(entries_field, ns, bs, body)

    {%Array.Map{
       keys_sorted: ks,
       length: n.length,
       null_count: n.null_count,
       validity: take_validity(body, v, n.length, n.null_count),
       offsets: take_slice(body, o),
       values: entries_array
     }, ns2, bs2}
  end

  defp decode_array(%Field{type: type}, _nodes, _buffers, _body) do
    raise ArgumentError, "Body.decode: unsupported array type #{inspect(type)}"
  end

  ## ---------------------------------------------------------------------
  ## Decode helpers
  ## ---------------------------------------------------------------------

  defp primitive_array_mod(%Arrow.Type.Int{bit_width: bw, signed: signed}) do
    case {bw, signed} do
      {8, true} -> Array.Int8
      {16, true} -> Array.Int16
      {32, true} -> Array.Int32
      {64, true} -> Array.Int64
      {8, false} -> Array.UInt8
      {16, false} -> Array.UInt16
      {32, false} -> Array.UInt32
      {64, false} -> Array.UInt64
    end
  end

  defp primitive_array_mod(%Arrow.Type.FloatingPoint{precision: :single}), do: Array.Float32
  defp primitive_array_mod(%Arrow.Type.FloatingPoint{precision: :double}), do: Array.Float64

  defp decimal_array_mod(32), do: Array.Decimal32
  defp decimal_array_mod(64), do: Array.Decimal64
  defp decimal_array_mod(128), do: Array.Decimal128
  defp decimal_array_mod(256), do: Array.Decimal256

  defp take_validity(_body, _b, _row_count, 0), do: nil

  defp take_validity(_body, %{length: 0}, row_count, _null_count) do
    # Producer omitted validity (zero-length buffer). Treat as all-valid.
    {bitmap, _} = Buf.pack_validity(List.duplicate(1, row_count))
    bitmap
  end

  defp take_validity(body, %{offset: off, length: len}, _row_count, _null_count) do
    binary_part(body, off, len)
  end

  defp take_bitmap(body, %{offset: off, length: len}, _row_count) when len > 0 do
    binary_part(body, off, len)
  end

  defp take_bitmap(_body, %{length: 0}, row_count) do
    {bitmap, _} = Buf.pack_validity(List.duplicate(1, row_count))
    bitmap
  end

  defp take_slice(body, %{offset: off, length: len}) do
    binary_part(body, off, len)
  end
end
