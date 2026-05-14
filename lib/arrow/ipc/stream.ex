defmodule Arrow.Ipc.Stream do
  @moduledoc """
  Encodes and decodes the Arrow IPC streaming format.

  An Arrow stream is a sequence of length-prefixed *messages*, each of
  which carries a FlatBuffers-encoded `Message` metadata table and,
  optionally, a raw body of column buffers.

  ## Frame layout per message

      continuation marker (u32 0xFFFFFFFF, 4 bytes)
      metadata length     (i32 little-endian, 4 bytes)
      metadata bytes      (variable, padded to 8-byte boundary)
      body bytes          (variable, already 8-byte aligned per buffer codec)

  An end-of-stream marker is the continuation marker followed by a zero
  length: `0xFFFFFFFF 0x00000000`. Some pre-0.15 producers omitted the
  continuation marker — `decode/1` accepts both forms.

  ## Stream composition

  A well-formed Arrow stream is:

      <Schema message>
      <RecordBatch message>
      <RecordBatch message>
      ...
      <EOS>

  DictionaryBatch messages (Tier 2) and footer interactions (file format)
  are out of scope here — they belong to `Arrow.Ipc.File` and the
  dictionary plumbing once that lands.
  """

  alias Arrow.Ipc.{Body, Flatbuf, Metadata}
  alias Arrow.Ipc.Flatbuf.Wire

  @continuation 0xFFFFFFFF
  @alignment 8
  @version :V5

  @doc """
  Builds a complete Arrow IPC stream from a schema, optional dictionaries
  registry, and zero or more record batches.
  """
  @spec encode(
          Arrow.Schema.t(),
          [Arrow.RecordBatch.t()],
          %{optional(non_neg_integer()) => Arrow.Array.t()}
        ) :: binary()
  def encode(%Arrow.Schema{} = schema, batches, dictionaries \\ %{})
      when is_list(batches) and is_map(dictionaries) do
    schema_frame = encode_schema_message(schema)
    dict_frames = encode_dictionary_messages(schema, dictionaries)
    batch_frames = Enum.map(batches, &encode_record_batch_message/1)

    IO.iodata_to_binary([schema_frame, dict_frames, batch_frames, eos()])
  end

  @doc """
  Parses a complete Arrow IPC stream binary into `{:ok, %{schema:,
  dictionaries:, batches:}}` or `{:error, reason}`.
  """
  @spec decode(binary()) ::
          {:ok,
           %{
             schema: Arrow.Schema.t(),
             dictionaries: %{optional(non_neg_integer()) => Arrow.Array.t()},
             batches: [Arrow.RecordBatch.t()]
           }}
          | {:error, term()}
  def decode(binary) when is_binary(binary) do
    {:ok, do_decode(binary, nil, %{}, [])}
  rescue
    e -> {:error, e}
  end

  ## ---------------------------------------------------------------------
  ## Encode (public frame builders + private composition)
  ## ---------------------------------------------------------------------

  @doc """
  Builds a single Schema message frame: continuation + length + padded
  metadata. No body. Returns iodata and the framing-inclusive metadata
  length (i.e. `8 + padded_metadata`).

  Exposed for `Arrow.Ipc.File`, which needs to record per-message file
  offsets in the Footer's Block list.
  """
  @spec schema_message_frame(Arrow.Schema.t()) :: {iodata(), non_neg_integer()}
  def schema_message_frame(%Arrow.Schema{} = schema) do
    metadata = build_message_metadata({:Schema, Metadata.schema_to_fb_map(schema)}, 0)
    {iodata, meta_len} = frame(metadata, <<>>)
    {iodata, meta_len}
  end

  @doc """
  Builds a single RecordBatch message frame: continuation + length +
  padded metadata + body. Returns iodata, the framing-inclusive metadata
  length, and the body length.

  Exposed for `Arrow.Ipc.File`, same reason as `schema_message_frame/1`.
  """
  @spec record_batch_message_frame(Arrow.RecordBatch.t()) ::
          {iodata(), non_neg_integer(), non_neg_integer()}
  def record_batch_message_frame(%Arrow.RecordBatch{} = batch) do
    %{length: row_count, nodes: nodes, buffers: buffers, body: body} = Body.encode(batch)

    metadata =
      build_message_metadata(
        {:RecordBatch, %{length: row_count, nodes: nodes, buffers: buffers}},
        byte_size(body)
      )

    {iodata, meta_len} = frame(metadata, body)
    {iodata, meta_len, byte_size(body)}
  end

  @doc """
  Builds a single DictionaryBatch message frame from a dictionary id
  and its values array. Returns iodata + framing-inclusive metadata
  length + body length.
  """
  @spec dictionary_batch_message_frame(non_neg_integer(), Arrow.Array.t()) ::
          {iodata(), non_neg_integer(), non_neg_integer()}
  def dictionary_batch_message_frame(id, array) when is_struct(array) do
    %{nodes: nodes, buffers: buffers, body: body} = Body.encode_array(array)
    row_count = Arrow.Array.length(array)

    dict_batch_map = %{
      id: id,
      data: %{length: row_count, nodes: nodes, buffers: buffers},
      isDelta: false
    }

    metadata =
      build_message_metadata({:DictionaryBatch, dict_batch_map}, byte_size(body))

    {iodata, meta_len} = frame(metadata, body)
    {iodata, meta_len, byte_size(body)}
  end

  @doc """
  End-of-stream marker: continuation marker followed by a zero length.
  """
  @spec eos() :: binary()
  def eos(), do: <<@continuation::little-32, 0::little-signed-32>>

  defp encode_schema_message(%Arrow.Schema{} = schema) do
    {iodata, _meta_len} = schema_message_frame(schema)
    iodata
  end

  defp encode_record_batch_message(%Arrow.RecordBatch{} = batch) do
    {iodata, _meta_len, _body_len} = record_batch_message_frame(batch)
    iodata
  end

  defp encode_dictionary_messages(%Arrow.Schema{} = schema, dictionaries)
       when is_map(dictionaries) do
    # Emit one DictionaryBatch message per (id, array) pair. Sort by id
    # for deterministic output.
    dictionaries
    |> Enum.sort_by(&elem(&1, 0))
    |> Enum.map(fn {id, array} ->
      Arrow.Field.find_by_dictionary_id(schema, id) ||
        raise(ArgumentError, "dictionary id #{id} has no referencing field in schema")

      {iodata, _meta_len, _body_len} = dictionary_batch_message_frame(id, array)
      iodata
    end)
  end

  defp build_message_metadata(header, body_length) do
    builder = Wire.new_builder()

    {builder, addr} =
      Flatbuf.Message.build(builder, %{
        version: @version,
        header: header,
        bodyLength: body_length
      })

    builder
    |> Wire.finish(addr)
    |> Wire.to_binary()
  end

  # Returns {iodata, framing_inclusive_metadata_length}. The length includes
  # the 8-byte continuation+length prefix per the Block spec: callers writing
  # the Footer Block descriptors record this value directly.
  defp frame(metadata, body) do
    padded_metadata = pad_to_alignment(metadata)
    len = byte_size(padded_metadata)
    iodata = [<<@continuation::little-32, len::little-signed-32>>, padded_metadata, body]
    {iodata, 8 + len}
  end

  defp pad_to_alignment(binary) do
    case rem(byte_size(binary), @alignment) do
      0 -> binary
      r -> binary <> <<0::size((@alignment - r) * 8)>>
    end
  end

  ## ---------------------------------------------------------------------
  ## Decode
  ## ---------------------------------------------------------------------

  defp do_decode(<<>>, schema, dicts, batches), do: build_result(schema, dicts, batches)

  # End-of-stream: continuation + zero length.
  defp do_decode(
         <<@continuation::little-32, 0::little-signed-32, _rest::binary>>,
         schema,
         dicts,
         batches
       ) do
    build_result(schema, dicts, batches)
  end

  # Standard framing with continuation marker.
  defp do_decode(
         <<@continuation::little-32, len::little-signed-32, rest::binary>>,
         schema,
         dicts,
         batches
       )
       when len > 0 do
    consume_frame(rest, len, schema, dicts, batches)
  end

  # Legacy framing without continuation marker. The first u32 is the length.
  defp do_decode(<<0::little-32, _rest::binary>>, schema, dicts, batches) do
    # Zero length without continuation = end of stream.
    build_result(schema, dicts, batches)
  end

  defp do_decode(<<len::little-signed-32, rest::binary>>, schema, dicts, batches) when len > 0 do
    consume_frame(rest, len, schema, dicts, batches)
  end

  defp consume_frame(rest, metadata_len, schema, dicts, batches) do
    <<metadata_padded::binary-size(metadata_len), after_metadata::binary>> = rest
    fb_message = decode_message_metadata(metadata_padded)
    body_len = fb_message.bodyLength

    <<body::binary-size(body_len), after_body::binary>> = after_metadata

    dispatch_message(fb_message, body, after_body, schema, dicts, batches)
  end

  defp dispatch_message(fb_message, body, rest, schema, dicts, batches) do
    handle_header(fb_message.header, body, rest, schema, dicts, batches)
  end

  defp handle_header({:Schema, fb_schema}, _body, rest, _schema, dicts, batches) do
    do_decode(rest, Metadata.schema_from_fb_struct(fb_schema), dicts, batches)
  end

  defp handle_header({:RecordBatch, fb_rb}, body, rest, schema, dicts, batches) do
    if schema == nil, do: raise(ArgumentError, "RecordBatch message before Schema")

    nodes = Enum.map(fb_rb.nodes, fn n -> %{length: n.length, null_count: n.null_count} end)
    buffers = Enum.map(fb_rb.buffers, fn b -> %{offset: b.offset, length: b.length} end)
    batch = Body.decode(schema, fb_rb.length, nodes, buffers, body)
    do_decode(rest, schema, dicts, [batch | batches])
  end

  defp handle_header({:DictionaryBatch, fb_db}, body, rest, schema, dicts, batches) do
    if schema == nil, do: raise(ArgumentError, "DictionaryBatch message before Schema")
    if fb_db.isDelta, do: raise(ArgumentError, "delta DictionaryBatch is not yet supported")

    field =
      Arrow.Field.find_by_dictionary_id(schema, fb_db.id) ||
        raise(ArgumentError, "DictionaryBatch references unknown id #{fb_db.id}")

    nodes = Enum.map(fb_db.data.nodes, fn n -> %{length: n.length, null_count: n.null_count} end)
    buffers = Enum.map(fb_db.data.buffers, fn b -> %{offset: b.offset, length: b.length} end)
    array = Body.decode_array_buffers(Arrow.Field.value_field(field), nodes, buffers, body)
    do_decode(rest, schema, Map.put(dicts, fb_db.id, array), batches)
  end

  defp handle_header({:Tensor, _}, _body, _rest, _schema, _dicts, _batches),
    do: raise(ArgumentError, "Tensor messages are out of scope for the stream reader")

  defp handle_header({:SparseTensor, _}, _body, _rest, _schema, _dicts, _batches),
    do: raise(ArgumentError, "SparseTensor messages are out of scope for the stream reader")

  defp handle_header(other, _body, _rest, _schema, _dicts, _batches),
    do: raise(ArgumentError, "unexpected Message header variant: #{inspect(other)}")

  defp decode_message_metadata(binary) do
    pos = Wire.root_table_pos(binary)
    Flatbuf.Message.decode_at(binary, pos)
  end

  defp build_result(nil, _dicts, _batches),
    do: raise(ArgumentError, "stream ended before Schema message")

  defp build_result(schema, dicts, batches) do
    %{schema: schema, dictionaries: dicts, batches: Enum.reverse(batches)}
  end
end
