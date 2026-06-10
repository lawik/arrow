defmodule Arrow.Ipc.File do
  @moduledoc """
  Encodes and decodes the Arrow IPC **file** format.

  The file format wraps the streaming format with magic bytes and a
  Footer FlatBuffers table that supports random access — consumers can
  jump straight to the footer and read individual record batches by
  offset, without scanning the whole stream linearly.

  ## On-disk layout

      "ARROW1\\0\\0"          (8 bytes magic prefix)
      <schema message>        (stream-format framing)
      <batch 0 message>
      <batch 1 message>
      ...
      <EOS>                   (continuation + zero length; 8 bytes)
      <Footer FlatBuffer>     (variable; contains schema + Block descriptors)
      <footer length>         (4 bytes, i32 little-endian)
      "ARROW1"                (6 bytes magic suffix)

  Each `Block` in the Footer is `{offset, metaDataLength, bodyLength}`,
  pointing at one record batch message within the file:

  - `offset` — absolute byte offset where the message's continuation
    marker starts.
  - `metaDataLength` — the framing-inclusive metadata size:
    `8 + padded_metadata_bytes`. Per the upstream spec the recorded
    value *includes* the 8-byte prefix.
  - `bodyLength` — the raw body byte count after the metadata.

  ## Notes

  - Dictionaries are written as DictionaryBatch messages between the
    Schema and the record batches, with Block descriptors recorded in
    the Footer's `dictionaries` list; decode reads them back through
    those Blocks (delta dictionaries are rejected).
  - The Schema appears once in the inline stream prefix and again in
    the Footer. Decode uses *only* the Footer's copy — the inline
    stream prefix is never parsed — and does not cross-check the two.

  ## Errors

  `decode/1` returns `{:ok, payload}` or `{:error, %Arrow.DecodeError{}}`
  with kind `:unsupported` (the input uses a feature this library
  deliberately rejects) or `:malformed` (the input is corrupt, truncated,
  or internally inconsistent). `decode!/1` raises the same error.
  """

  alias Arrow.Ipc.{Body, Flatbuf, Metadata, Stream}
  alias Arrow.Ipc.Flatbuf.Wire

  @magic "ARROW1\0\0"
  @magic_suffix "ARROW1"
  @version :V5
  @continuation 0xFFFFFFFF

  @typedoc "Everything a decoded file carries: schema, dictionary registry, batches."
  @type payload :: %{
          schema: Arrow.Schema.t(),
          dictionaries: %{optional(non_neg_integer()) => Arrow.Array.t()},
          batches: [Arrow.RecordBatch.t()]
        }

  ## ---------------------------------------------------------------------
  ## Encode
  ## ---------------------------------------------------------------------

  @doc """
  Encodes a schema, an optional dictionaries registry, and zero or more
  record batches into a complete Arrow IPC file as a binary.
  """
  @spec encode(
          Arrow.Schema.t(),
          [Arrow.RecordBatch.t()],
          %{optional(non_neg_integer()) => Arrow.Array.t()}
        ) :: binary()
  def encode(%Arrow.Schema{} = schema, batches, dictionaries \\ %{})
      when is_list(batches) and is_map(dictionaries) do
    Stream.validate_dictionaries!(schema, dictionaries)
    {schema_frame, _schema_meta_len} = Stream.schema_message_frame(schema)
    schema_frame_bin = IO.iodata_to_binary(schema_frame)

    offset_after_magic = byte_size(@magic)
    offset_after_schema = offset_after_magic + byte_size(schema_frame_bin)

    # Dictionary messages first, then record batches.
    {dict_chunks_rev, dict_blocks_rev, offset_after_dicts} =
      dictionaries
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.reduce({[], [], offset_after_schema}, fn {id, array}, {chunks, blocks, off} ->
        {iodata, meta_len, body_len} = Stream.dictionary_batch_message_frame(id, array)
        chunk_bin = IO.iodata_to_binary(iodata)
        block = %{offset: off, metaDataLength: meta_len, bodyLength: body_len}
        next_off = off + byte_size(chunk_bin)
        {[chunk_bin | chunks], [block | blocks], next_off}
      end)

    {batch_chunks_rev, batch_blocks_rev, _final_off} =
      Enum.reduce(batches, {[], [], offset_after_dicts}, fn batch, {chunks, blocks, off} ->
        {iodata, meta_len, body_len} = Stream.record_batch_message_frame(batch)
        chunk_bin = IO.iodata_to_binary(iodata)
        block = %{offset: off, metaDataLength: meta_len, bodyLength: body_len}
        next_off = off + byte_size(chunk_bin)
        {[chunk_bin | chunks], [block | blocks], next_off}
      end)

    dict_chunks = Enum.reverse(dict_chunks_rev)
    dict_blocks = Enum.reverse(dict_blocks_rev)
    batch_chunks = Enum.reverse(batch_chunks_rev)
    batch_blocks = Enum.reverse(batch_blocks_rev)

    footer_bin = build_footer(schema, dict_blocks, batch_blocks)

    IO.iodata_to_binary([
      @magic,
      schema_frame_bin,
      dict_chunks,
      batch_chunks,
      Stream.eos(),
      footer_bin,
      <<byte_size(footer_bin)::little-signed-32>>,
      @magic_suffix
    ])
  end

  defp build_footer(%Arrow.Schema{} = schema, dict_blocks, batch_blocks) do
    builder = Wire.new_builder()

    {builder, addr} =
      Flatbuf.Footer.build(builder, %{
        version: @version,
        schema: Metadata.schema_to_fb_map(schema),
        dictionaries: dict_blocks,
        recordBatches: batch_blocks
      })

    builder
    |> Wire.finish(addr)
    |> Wire.to_binary()
  end

  ## ---------------------------------------------------------------------
  ## Decode
  ## ---------------------------------------------------------------------

  @doc """
  Parses an Arrow IPC file binary into `{:ok, %{schema:, dictionaries:,
  batches:}}` or `{:error, %Arrow.DecodeError{}}`.
  """
  @spec decode(binary()) :: {:ok, payload()} | {:error, Arrow.DecodeError.t()}
  def decode(binary) when is_binary(binary) do
    {:ok, do_decode(binary)}
  rescue
    e in Arrow.DecodeError ->
      {:error, e}

    e in [MatchError, FunctionClauseError, ArgumentError] ->
      {:error,
       %Arrow.DecodeError{
         kind: :malformed,
         message: "malformed or truncated input: " <> Exception.message(e)
       }}
  end

  @doc """
  Like `decode/1`, but returns the payload directly and raises
  `Arrow.DecodeError` on failure.
  """
  @spec decode!(binary()) :: payload()
  def decode!(binary) when is_binary(binary) do
    case decode(binary) do
      {:ok, payload} -> payload
      {:error, %Arrow.DecodeError{} = e} -> raise e
    end
  end

  defp do_decode(binary) do
    size = byte_size(binary)

    if size < byte_size(@magic) + byte_size(@magic_suffix) + 4 do
      raise Arrow.DecodeError,
        kind: :malformed,
        message: "buffer too small to be an Arrow IPC file (#{size} bytes)"
    end

    <<@magic, _rest::binary>> = binary

    suffix_start = size - byte_size(@magic_suffix)
    <<_::binary-size(suffix_start), @magic_suffix>> = binary

    footer_length_offset = size - byte_size(@magic_suffix) - 4

    <<_::binary-size(footer_length_offset), footer_length::little-signed-32, _rest::binary>> =
      binary

    footer_offset = footer_length_offset - footer_length

    <<_::binary-size(footer_offset), footer_bin::binary-size(footer_length), _rest::binary>> =
      binary

    fb_footer = Flatbuf.Footer.decode_at(footer_bin, Wire.root_table_pos(footer_bin))
    schema = Metadata.schema_from_fb_struct(fb_footer.schema)

    dictionaries =
      fb_footer.dictionaries
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce(%{}, fn block, acc ->
        {id, array} = decode_dictionary_block(binary, block, schema)
        Map.put(acc, id, array)
      end)

    batches =
      fb_footer.recordBatches
      |> Enum.reject(&is_nil/1)
      |> Enum.map(fn block -> decode_batch_block(binary, block, schema) end)

    %{schema: schema, dictionaries: dictionaries, batches: batches}
  end

  defp decode_batch_block(binary, block, schema) do
    {fb_message, body} = read_block(binary, block)

    case fb_message.header do
      {:RecordBatch, fb_rb} ->
        %{length: length, nodes: nodes, buffers: buffers} =
          Metadata.record_batch_descriptors(fb_rb)

        Body.decode(schema, length, nodes, buffers, body)

      other ->
        raise Arrow.DecodeError,
          kind: :malformed,
          message: "file Block points at non-RecordBatch message: #{inspect(other)}"
    end
  end

  defp decode_dictionary_block(binary, block, schema) do
    {fb_message, body} = read_block(binary, block)

    case fb_message.header do
      {:DictionaryBatch, fb_db} ->
        if fb_db.isDelta do
          raise Arrow.DecodeError,
            kind: :unsupported,
            message: "delta DictionaryBatch is not yet supported"
        end

        field =
          Arrow.Field.find_by_dictionary_id(schema, fb_db.id) ||
            raise(Arrow.DecodeError,
              kind: :malformed,
              message: "DictionaryBatch references unknown id #{fb_db.id}"
            )

        %{nodes: nodes, buffers: buffers} = Metadata.record_batch_descriptors(fb_db.data)
        array = Body.decode_array_buffers(Arrow.Field.value_field(field), nodes, buffers, body)
        {fb_db.id, array}

      other ->
        raise Arrow.DecodeError,
          kind: :malformed,
          message: "dictionary Block points at non-DictionaryBatch: #{inspect(other)}"
    end
  end

  defp read_block(binary, block) do
    off = block.offset
    meta_len_with_prefix = block.metaDataLength
    body_len = block.bodyLength
    meta_bytes_len = meta_len_with_prefix - 8

    <<_::binary-size(off), marker::little-32, _meta_len::little-signed-32,
      metadata::binary-size(meta_bytes_len), body::binary-size(body_len), _rest::binary>> = binary

    if marker != @continuation do
      raise Arrow.DecodeError,
        kind: :malformed,
        message:
          "Block at offset #{off} does not start with the 0xFFFFFFFF continuation " <>
            "marker; unsupported: legacy (pre-0.15 / V4) file framing, or the Block " <>
            "offset is corrupt"
    end

    fb_message = Flatbuf.Message.decode_at(metadata, Wire.root_table_pos(metadata))
    {fb_message, body}
  end
end
