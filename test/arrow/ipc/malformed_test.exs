defmodule Arrow.Ipc.MalformedTest do
  @moduledoc """
  Decoders must reject malformed input with `{:error, _}` — never raise,
  hang, or return data. The error *reason* is deliberately not pinned
  beyond shape: today it is often a raw exception struct, which is not a
  stable contract.
  """

  use ExUnit.Case, async: true

  alias Arrow.{Array, Buffer, Field, RecordBatch, Schema, Type}
  alias Arrow.Ipc.File, as: IpcFile
  alias Arrow.Ipc.Stream

  defp valid_payload do
    schema = %Schema{
      fields: [%Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: false}]
    }

    batch = %RecordBatch{
      schema: schema,
      length: 2,
      columns: [
        %Array.Int32{length: 2, null_count: 0, values: Buffer.pack_primitive([1, 2], :int32)}
      ]
    }

    {schema, [batch]}
  end

  describe "Stream.decode/1" do
    test "empty binary" do
      assert {:error, _} = Stream.decode(<<>>)
    end

    test "garbage bytes" do
      assert {:error, _} = Stream.decode(<<1, 2, 3>>)
    end

    test "end-of-stream marker with no Schema message" do
      assert {:error, _} = Stream.decode(<<0xFFFFFFFF::little-32, 0::little-32>>)
    end

    test "valid stream truncated mid-body" do
      {schema, batches} = valid_payload()
      bin = Stream.encode(schema, batches)
      assert {:error, _} = Stream.decode(binary_part(bin, 0, byte_size(bin) - 9))
    end
  end

  describe "File.decode/1" do
    test "wrong magic" do
      assert {:error, _} = IpcFile.decode("NOTANARROWFILE000000")
    end

    test "buffer smaller than the fixed framing" do
      assert {:error, _} = IpcFile.decode("ARROW1")
    end

    test "valid file with truncated tail" do
      {schema, batches} = valid_payload()
      bin = IpcFile.encode(schema, batches)
      assert {:error, _} = IpcFile.decode(binary_part(bin, 0, byte_size(bin) - 7))
    end

    test "footer length pointing outside the buffer" do
      {schema, batches} = valid_payload()
      bin = IpcFile.encode(schema, batches)
      prefix = binary_part(bin, 0, byte_size(bin) - 10)
      assert {:error, _} = IpcFile.decode(prefix <> <<999_999_999::little-signed-32, "ARROW1">>)
    end
  end

  describe "Json.decode/1" do
    test "invalid JSON" do
      assert {:error, _} = Arrow.Json.decode("{")
    end

    test "JSON object missing the schema key" do
      assert {:error, _} = Arrow.Json.decode("{}")
    end
  end
end
