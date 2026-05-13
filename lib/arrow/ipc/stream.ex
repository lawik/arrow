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
  Builds a complete Arrow IPC stream from a schema and zero or more
  record batches.
  """
  @spec encode(Arrow.Schema.t(), [Arrow.RecordBatch.t()]) :: binary()
  def encode(%Arrow.Schema{} = schema, batches) when is_list(batches) do
    schema_frame = encode_schema_message(schema)
    batch_frames = Enum.map(batches, &encode_record_batch_message/1)
    eos = <<@continuation::little-32, 0::little-signed-32>>

    IO.iodata_to_binary([schema_frame, batch_frames, eos])
  end

  @doc """
  Parses a complete Arrow IPC stream binary into `{:ok, %{schema:,
  batches:}}` or `{:error, reason}`.
  """
  @spec decode(binary()) ::
          {:ok, %{schema: Arrow.Schema.t(), batches: [Arrow.RecordBatch.t()]}}
          | {:error, term()}
  def decode(binary) when is_binary(binary) do
    {:ok, do_decode(binary, nil, [])}
  rescue
    e -> {:error, e}
  end

  ## ---------------------------------------------------------------------
  ## Encode
  ## ---------------------------------------------------------------------

  defp encode_schema_message(%Arrow.Schema{} = schema) do
    metadata = build_message_metadata({:Schema, Metadata.schema_to_fb_map(schema)}, 0)
    frame(metadata, <<>>)
  end

  defp encode_record_batch_message(%Arrow.RecordBatch{} = batch) do
    %{length: row_count, nodes: nodes, buffers: buffers, body: body} = Body.encode(batch)

    metadata =
      build_message_metadata(
        {:RecordBatch, %{length: row_count, nodes: nodes, buffers: buffers}},
        byte_size(body)
      )

    frame(metadata, body)
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

  defp frame(metadata, body) do
    padded_metadata = pad_to_alignment(metadata)
    len = byte_size(padded_metadata)

    [
      <<@continuation::little-32, len::little-signed-32>>,
      padded_metadata,
      body
    ]
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

  defp do_decode(<<>>, schema, batches), do: build_result(schema, batches)

  # End-of-stream: continuation + zero length.
  defp do_decode(
         <<@continuation::little-32, 0::little-signed-32, _rest::binary>>,
         schema,
         batches
       ) do
    build_result(schema, batches)
  end

  # Standard framing with continuation marker.
  defp do_decode(
         <<@continuation::little-32, len::little-signed-32, rest::binary>>,
         schema,
         batches
       )
       when len > 0 do
    consume_frame(rest, len, schema, batches)
  end

  # Legacy framing without continuation marker. The first u32 is the length.
  defp do_decode(<<0::little-32, _rest::binary>>, schema, batches) do
    # Zero length without continuation = end of stream.
    build_result(schema, batches)
  end

  defp do_decode(<<len::little-signed-32, rest::binary>>, schema, batches) when len > 0 do
    consume_frame(rest, len, schema, batches)
  end

  defp consume_frame(rest, metadata_len, schema, batches) do
    <<metadata_padded::binary-size(metadata_len), after_metadata::binary>> = rest
    fb_message = decode_message_metadata(metadata_padded)
    body_len = fb_message.bodyLength

    <<body::binary-size(body_len), after_body::binary>> = after_metadata

    dispatch_message(fb_message, body, after_body, schema, batches)
  end

  defp dispatch_message(fb_message, body, rest, schema, batches) do
    case fb_message.header do
      {:Schema, fb_schema} ->
        new_schema = Metadata.schema_from_fb_struct(fb_schema)
        do_decode(rest, new_schema, batches)

      {:RecordBatch, fb_rb} ->
        if schema == nil do
          raise ArgumentError, "RecordBatch message before Schema"
        end

        nodes = Enum.map(fb_rb.nodes, fn n -> %{length: n.length, null_count: n.null_count} end)
        buffers = Enum.map(fb_rb.buffers, fn b -> %{offset: b.offset, length: b.length} end)
        batch = Body.decode(schema, fb_rb.length, nodes, buffers, body)
        do_decode(rest, schema, [batch | batches])

      {:DictionaryBatch, _} ->
        raise ArgumentError, "DictionaryBatch messages are not yet supported"

      {:Tensor, _} ->
        raise ArgumentError, "Tensor messages are out of scope for the stream reader"

      {:SparseTensor, _} ->
        raise ArgumentError, "SparseTensor messages are out of scope for the stream reader"

      other ->
        raise ArgumentError, "unexpected Message header variant: #{inspect(other)}"
    end
  end

  defp decode_message_metadata(binary) do
    pos = Wire.root_table_pos(binary)
    Flatbuf.Message.decode_at(binary, pos)
  end

  defp build_result(nil, _batches), do: raise(ArgumentError, "stream ended before Schema message")

  defp build_result(schema, batches) do
    %{schema: schema, batches: Enum.reverse(batches)}
  end
end
