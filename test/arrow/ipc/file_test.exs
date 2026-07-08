# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.Ipc.FileTest do
  use ExUnit.Case, async: true

  alias Arrow.{Array, Buffer, Field, Logical, RecordBatch, Schema, Type}
  alias Arrow.Ipc.File, as: IpcFile

  defp int32(values) do
    %Array.Int32{
      length: length(values),
      null_count: 0,
      validity: nil,
      values: Buffer.pack_primitive(values, :int32)
    }
  end

  defp utf8(strings) do
    lengths = Enum.map(strings, &byte_size/1)

    %Array.Utf8{
      length: length(strings),
      null_count: 0,
      validity: nil,
      offsets: Buffer.pack_int32_offsets(lengths),
      values: IO.iodata_to_binary(strings)
    }
  end

  test "magic prefix and suffix" do
    schema = %Schema{
      fields: [%Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: false}]
    }

    bin = IpcFile.encode(schema, [])
    assert <<"ARROW1", 0, 0, _rest::binary>> = bin
    suffix_start = byte_size(bin) - 6
    assert <<_::binary-size(^suffix_start), "ARROW1">> = bin
  end

  test "empty (schema only) round-trip" do
    schema = %Schema{
      fields: [%Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: false}]
    }

    bin = IpcFile.encode(schema, [])
    {:ok, %{schema: decoded_schema, batches: []}} = IpcFile.decode(bin)
    assert decoded_schema == schema
  end

  test "single batch round-trip" do
    schema = %Schema{
      fields: [%Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: false}]
    }

    batch = %RecordBatch{schema: schema, length: 3, columns: [int32([10, 20, 30])]}

    bin = IpcFile.encode(schema, [batch])
    {:ok, decoded} = IpcFile.decode(bin)

    assert decoded.schema == schema
    assert length(decoded.batches) == 1
    assert Logical.batches_equal?(hd(decoded.batches), batch)
  end

  test "multi-batch with mixed columns round-trips and the Footer's Block offsets are correct" do
    schema = %Schema{
      fields: [
        %Field{name: "n", type: %Type.Int{bit_width: 32, signed: true}, nullable: false},
        %Field{name: "s", type: %Type.Utf8{}, nullable: false}
      ]
    }

    batch1 = %RecordBatch{
      schema: schema,
      length: 2,
      columns: [int32([1, 2]), utf8(["foo", "bar"])]
    }

    batch2 = %RecordBatch{
      schema: schema,
      length: 3,
      columns: [int32([3, 4, 5]), utf8(["", "baz", "quux"])]
    }

    bin = IpcFile.encode(schema, [batch1, batch2])
    {:ok, decoded} = IpcFile.decode(bin)

    assert decoded.schema == schema
    assert length(decoded.batches) == 2
    assert Logical.batches_equal?(Enum.at(decoded.batches, 0), batch1)
    assert Logical.batches_equal?(Enum.at(decoded.batches, 1), batch2)
  end
end
