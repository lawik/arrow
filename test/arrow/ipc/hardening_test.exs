# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.Ipc.HardeningTest do
  @moduledoc """
  Regression tests for correctness hardening in the IPC layer:
  compressed-body rejection, big-endian and Float16 schema rejection,
  encode-side dictionary registry validation, push_buffer length
  invariants, validity/node consistency, duplicate Schema messages, and
  file Block continuation-marker verification.
  """

  use ExUnit.Case, async: true

  alias Arrow.{Array, Buffer, Field, RecordBatch, Schema, Type}
  alias Arrow.Ipc.{Body, Flatbuf, Metadata}

  @golden Path.expand("../../golden", __DIR__)

  ## ---------------------------------------------------------------------
  ## Compressed bodies (pyarrow LZ4 golden fixtures)
  ## ---------------------------------------------------------------------

  describe "compressed record batch bodies" do
    test "LZ4-compressed stream is rejected as unsupported" do
      bin = File.read!(Path.join(@golden, "compressed.stream"))

      assert {:error, %Arrow.DecodeError{kind: :unsupported, message: msg}} =
               Arrow.Ipc.Stream.decode(bin)

      assert msg =~ "compressed record batch body"
    end

    test "LZ4-compressed file is rejected as unsupported" do
      bin = File.read!(Path.join(@golden, "compressed.arrow"))

      assert {:error, %Arrow.DecodeError{kind: :unsupported, message: msg}} =
               Arrow.Ipc.File.decode(bin)

      assert msg =~ "compressed record batch body"
    end
  end

  ## ---------------------------------------------------------------------
  ## Schema-level rejections (metadata layer)
  ## ---------------------------------------------------------------------

  describe "schema decoding rejections" do
    test "big-endian schema raises an unsupported Arrow.DecodeError" do
      fb = %Flatbuf.Schema{endianness: :Big, fields: [], custom_metadata: [], features: []}

      e = assert_raise(Arrow.DecodeError, fn -> Metadata.schema_from_fb_struct(fb) end)
      assert e.kind == :unsupported
      assert e.message =~ "big-endian"
    end

    test "Float16 (HALF precision) field raises an unsupported Arrow.DecodeError" do
      fb_field = %Flatbuf.Field{
        name: "h",
        nullable: true,
        type: {:FloatingPoint, %Flatbuf.FloatingPoint{precision: :HALF}},
        dictionary: nil,
        children: [],
        custom_metadata: []
      }

      fb = %Flatbuf.Schema{
        endianness: :Little,
        fields: [fb_field],
        custom_metadata: [],
        features: []
      }

      e = assert_raise(Arrow.DecodeError, fn -> Metadata.schema_from_fb_struct(fb) end)
      assert e.kind == :unsupported
      assert e.message =~ "HALF"
    end
  end

  ## ---------------------------------------------------------------------
  ## Encode-side dictionary registry validation
  ## ---------------------------------------------------------------------

  describe "dictionary-encoded field without registry entry" do
    defp dict_schema do
      %Schema{
        fields: [
          %Field{
            name: "d",
            type: %Type.Utf8{},
            nullable: true,
            dictionary: %Type.DictionaryEncoding{
              id: 7,
              index_type: %Type.Int{bit_width: 8, signed: true}
            }
          }
        ]
      }
    end

    test "Stream.encode raises when the registry is missing the id" do
      e =
        assert_raise(ArgumentError, fn -> Arrow.Ipc.Stream.encode(dict_schema(), [], %{}) end)

      assert e.message =~ "id 7"
      refute e.message =~ "unsupported"
    end

    test "File.encode raises when the registry is missing the id" do
      assert_raise ArgumentError, ~r/id 7/, fn ->
        Arrow.Ipc.File.encode(dict_schema(), [], %{})
      end
    end

    test "a populated registry still encodes and round-trips" do
      values = utf8(["a", "b"])
      bin = Arrow.Ipc.Stream.encode(dict_schema(), [], %{7 => values})

      assert {:ok, %{dictionaries: %{7 => %Array.Utf8{length: 2}}}} =
               Arrow.Ipc.Stream.decode(bin)
    end
  end

  ## ---------------------------------------------------------------------
  ## push_buffer length invariant
  ## ---------------------------------------------------------------------

  describe "push_buffer length invariant" do
    test "undersized buffer raises (no silent body desync)" do
      # 9 rows need a 2-byte validity bitmap; hand it 1 byte.
      arr = %Array.Int32{
        length: 9,
        null_count: 1,
        validity: <<0xFF>>,
        values: <<0::size(9 * 32)>>
      }

      e = assert_raise(ArgumentError, fn -> Body.encode_array(arr) end)
      assert e.message =~ "descriptor declares"
      refute e.message =~ "unsupported"
    end

    test "oversized (padded) buffer is truncated and the output decodes correctly" do
      # A validity bitmap carrying its 8-byte alignment padding, as kept
      # when re-encoding buffers sliced out of a foreign IPC body. Only
      # 1 byte is meaningful for 5 rows; the descriptor must say 1, and
      # the following column must not be shifted by the extra 7 bytes.
      {validity, 1} = Buffer.pack_validity([1, 0, 1, 1, 1])
      padded_validity = validity <> <<0::size(7 * 8)>>

      ints = %Array.Int32{
        length: 5,
        null_count: 1,
        validity: padded_validity,
        values: Buffer.pack_primitive([1, 0, 3, 4, 5], :int32)
      }

      strings = utf8(["a", "bb", "ccc", "dddd", "eeeee"])

      schema = %Schema{
        fields: [
          %Field{name: "i", type: %Type.Int{bit_width: 32, signed: true}},
          %Field{name: "s", type: %Type.Utf8{}, nullable: false}
        ]
      }

      batch = %RecordBatch{schema: schema, length: 5, columns: [ints, strings]}

      assert {:ok, %{batches: [decoded]}} =
               schema |> Arrow.Ipc.Stream.encode([batch]) |> Arrow.Ipc.Stream.decode()

      assert [%Array.Int32{} = dec_ints, %Array.Utf8{} = dec_strings] = decoded.columns
      assert Buffer.unpack_validity(dec_ints.validity, 5) == [1, 0, 1, 1, 1]
      assert dec_ints.values == ints.values
      assert dec_strings.offsets == strings.offsets
      assert dec_strings.values == strings.values
    end
  end

  ## ---------------------------------------------------------------------
  ## Validity / node consistency on decode
  ## ---------------------------------------------------------------------

  describe "zero-length buffers vs. node claims" do
    test "zero-length validity with null_count > 0 raises instead of fabricating a bitmap" do
      schema = %Schema{
        fields: [%Field{name: "i", type: %Type.Int{bit_width: 32, signed: true}}]
      }

      nodes = [%{length: 4, null_count: 2}]
      buffers = [%{offset: 0, length: 0}, %{offset: 0, length: 16}]

      e =
        assert_raise(Arrow.DecodeError, fn ->
          Body.decode(schema, 4, nodes, buffers, <<0::size(16 * 8)>>)
        end)

      assert e.kind == :malformed
      assert e.message =~ "zero declared length"
    end

    test "zero-length Bool values buffer with rows raises" do
      schema = %Schema{fields: [%Field{name: "b", type: %Type.Bool{}}]}
      nodes = [%{length: 3, null_count: 0}]
      buffers = [%{offset: 0, length: 0}, %{offset: 0, length: 0}]

      assert_raise Arrow.DecodeError, ~r/Bool values buffer/, fn ->
        Body.decode(schema, 3, nodes, buffers, <<>>)
      end
    end

    test "legitimate paths survive: omitted validity and zero-row Bool" do
      schema = %Schema{fields: [%Field{name: "b", type: %Type.Bool{}}]}

      # null_count == 0 with a zero-length validity buffer decodes to nil.
      nodes = [%{length: 3, null_count: 0}]
      buffers = [%{offset: 0, length: 0}, %{offset: 0, length: 8}]
      batch = Body.decode(schema, 3, nodes, buffers, <<0b101, 0::size(7 * 8)>>)
      assert [%Array.Bool{length: 3, validity: nil}] = batch.columns

      # A zero-row batch needs no bytes at all.
      nodes = [%{length: 0, null_count: 0}]
      buffers = [%{offset: 0, length: 0}, %{offset: 0, length: 0}]
      batch = Body.decode(schema, 0, nodes, buffers, <<>>)
      assert [%Array.Bool{length: 0, validity: nil, values: <<>>}] = batch.columns
    end
  end

  ## ---------------------------------------------------------------------
  ## Stream / file framing
  ## ---------------------------------------------------------------------

  describe "framing hardening" do
    test "a duplicate Schema message mid-stream is an error" do
      schema = %Schema{fields: [%Field{name: "i", type: %Type.Int{bit_width: 32, signed: true}}]}

      bin = Arrow.Ipc.Stream.encode(schema, [])
      schema_frame = binary_part(bin, 0, byte_size(bin) - byte_size(Arrow.Ipc.Stream.eos()))
      doubled = schema_frame <> schema_frame <> Arrow.Ipc.Stream.eos()

      assert {:error, %Arrow.DecodeError{kind: :malformed, message: msg}} =
               Arrow.Ipc.Stream.decode(doubled)

      assert msg =~ "duplicate Schema"
    end

    test "a file Block offset that misses the continuation marker is an error" do
      schema = %Schema{
        fields: [%Field{name: "i", type: %Type.Int{bit_width: 32, signed: true}}]
      }

      ints = %Array.Int32{
        length: 3,
        null_count: 0,
        validity: nil,
        values: Buffer.pack_primitive([1, 2, 3], :int32)
      }

      batch = %RecordBatch{schema: schema, length: 3, columns: [ints]}
      file_bin = Arrow.Ipc.File.encode(schema, [batch])

      # The batch Block points just past magic + schema frame; zero out
      # its continuation marker to simulate a corrupt offset (or legacy
      # V4 framing, which has no marker).
      {_frame, schema_meta_len} = Arrow.Ipc.Stream.schema_message_frame(schema)
      block_offset = 8 + schema_meta_len

      <<pre::binary-size(block_offset), _marker::binary-size(4), rest::binary>> = file_bin
      corrupt = pre <> <<0, 0, 0, 0>> <> rest

      assert {:ok, _} = Arrow.Ipc.File.decode(file_bin)

      assert {:error, %Arrow.DecodeError{kind: :malformed, message: msg}} =
               Arrow.Ipc.File.decode(corrupt)

      assert msg =~ "continuation"
    end
  end

  ## ---------------------------------------------------------------------
  ## Helpers
  ## ---------------------------------------------------------------------

  defp utf8(strings) do
    %Array.Utf8{
      length: length(strings),
      null_count: 0,
      validity: nil,
      offsets: Buffer.pack_int32_offsets(Enum.map(strings, &byte_size/1)),
      values: IO.iodata_to_binary(strings)
    }
  end
end
