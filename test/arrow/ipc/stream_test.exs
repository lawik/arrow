# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.Ipc.StreamTest do
  use ExUnit.Case, async: true

  alias Arrow.{Array, Buffer, Field, RecordBatch, Schema, Type}
  alias Arrow.Ipc.Stream

  defp int32_array(values) do
    %Array.Int32{
      length: length(values),
      null_count: 0,
      validity: nil,
      values: Buffer.pack_primitive(values, :int32)
    }
  end

  defp utf8_array(strings) do
    lengths = Enum.map(strings, &byte_size/1)

    %Array.Utf8{
      length: length(strings),
      null_count: 0,
      validity: nil,
      offsets: Buffer.pack_int32_offsets(lengths),
      values: IO.iodata_to_binary(strings)
    }
  end

  test "empty stream (schema only, no batches)" do
    schema = %Schema{
      fields: [%Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: false}]
    }

    encoded = Stream.encode(schema, [])
    assert is_binary(encoded)
    assert byte_size(encoded) > 0

    {:ok, %{schema: decoded_schema, batches: []}} = Stream.decode(encoded)
    assert decoded_schema == schema
  end

  test "single batch round-trip" do
    schema = %Schema{
      fields: [%Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: false}]
    }

    batch = %RecordBatch{schema: schema, length: 3, columns: [int32_array([10, 20, 30])]}

    encoded = Stream.encode(schema, [batch])
    {:ok, decoded} = Stream.decode(encoded)

    assert decoded.schema == schema
    assert decoded.batches == [batch]
  end

  test "multi-batch round-trip" do
    schema = %Schema{
      fields: [
        %Field{name: "n", type: %Type.Int{bit_width: 32, signed: true}, nullable: false},
        %Field{name: "s", type: %Type.Utf8{}, nullable: false}
      ]
    }

    batch1 = %RecordBatch{
      schema: schema,
      length: 2,
      columns: [int32_array([1, 2]), utf8_array(["foo", "bar"])]
    }

    batch2 = %RecordBatch{
      schema: schema,
      length: 3,
      columns: [int32_array([3, 4, 5]), utf8_array(["", "baz", "quux"])]
    }

    encoded = Stream.encode(schema, [batch1, batch2])
    {:ok, decoded} = Stream.decode(encoded)

    assert decoded.schema == schema
    assert decoded.batches == [batch1, batch2]
  end

  test "framing has 8-byte aligned metadata" do
    schema = %Schema{
      fields: [%Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: false}]
    }

    encoded = Stream.encode(schema, [])

    # First 4 bytes: continuation marker 0xFFFFFFFF (LE).
    <<0xFFFFFFFF::little-32, metadata_len::little-signed-32, _rest::binary>> = encoded

    assert rem(metadata_len, 8) == 0
  end
end
