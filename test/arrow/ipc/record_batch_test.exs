defmodule Arrow.Ipc.RecordBatchTest do
  use ExUnit.Case, async: true

  alias Arrow.{Array, Buffer, Field, RecordBatch, Schema, Type}
  alias Arrow.Ipc.Metadata

  defp encoded_array(:int32, values, validity_flags) do
    {bitmap, null_count} = Buffer.pack_validity(validity_flags)
    # Canonicalize: validity is nil when there are no nulls. Matches what the
    # decoder produces and what real Arrow producers emit.
    validity = if null_count == 0, do: nil, else: bitmap

    %Array.Int32{
      length: length(values),
      null_count: null_count,
      validity: validity,
      values: Buffer.pack_primitive(values, :int32)
    }
  end

  defp encoded_array(:utf8, strings) do
    lengths = Enum.map(strings, &byte_size/1)

    %Array.Utf8{
      length: length(strings),
      null_count: 0,
      validity: nil,
      offsets: Buffer.pack_int32_offsets(lengths),
      values: IO.iodata_to_binary(strings)
    }
  end

  defp round_trip(%RecordBatch{} = batch) do
    %{metadata: metadata, body: body, length: row_count} = Metadata.encode_record_batch(batch)
    assert is_binary(metadata)
    assert is_binary(body)
    assert row_count == batch.length
    # Body should be 8-byte aligned in total length.
    assert rem(byte_size(body), 8) == 0

    {:ok, decoded} = Metadata.decode_record_batch(metadata, body, batch.schema)
    assert decoded == batch
  end

  test "Int32 column" do
    schema = %Schema{
      fields: [%Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: true}]
    }

    column = encoded_array(:int32, [1, -2, 3, 0, 5], [1, 1, 0, 0, 1])

    round_trip(%RecordBatch{schema: schema, length: 5, columns: [column]})
  end

  test "two columns: Int32 + Utf8" do
    schema = %Schema{
      fields: [
        %Field{name: "n", type: %Type.Int{bit_width: 32, signed: true}, nullable: false},
        %Field{name: "name", type: %Type.Utf8{}, nullable: true}
      ]
    }

    int_col = encoded_array(:int32, [10, 20, 30], [1, 1, 1])
    utf_col = encoded_array(:utf8, ["foo", "bar", "baz"])

    round_trip(%RecordBatch{schema: schema, length: 3, columns: [int_col, utf_col]})
  end

  test "Null column carries length only" do
    schema = %Schema{fields: [%Field{name: "n", type: %Type.Null{}, nullable: true}]}
    batch = %RecordBatch{schema: schema, length: 7, columns: [%Array.Null{length: 7}]}

    round_trip(batch)
  end

  test "Bool column with nulls" do
    schema = %Schema{fields: [%Field{name: "b", type: %Type.Bool{}, nullable: true}]}
    {validity, nc} = Buffer.pack_validity([1, 0, 1, 1])
    values = Buffer.pack_bool_values([1, 0, 0, 1])

    column = %Array.Bool{length: 4, null_count: nc, validity: validity, values: values}

    round_trip(%RecordBatch{schema: schema, length: 4, columns: [column]})
  end

  test "Float64 column without nulls (validity omitted)" do
    schema = %Schema{
      fields: [
        %Field{name: "f", type: %Type.FloatingPoint{precision: :double}, nullable: false}
      ]
    }

    column = %Array.Float64{
      length: 3,
      null_count: 0,
      validity: nil,
      values: Buffer.pack_primitive([3.14, 2.71, 1.41], :float64)
    }

    round_trip(%RecordBatch{schema: schema, length: 3, columns: [column]})
  end

  test "List<Int32>" do
    schema = %Schema{
      fields: [
        %Field{
          name: "l",
          type: %Type.List{},
          nullable: true,
          children: [
            %Field{name: "item", type: %Type.Int{bit_width: 32, signed: true}, nullable: true}
          ]
        }
      ]
    }

    inner = encoded_array(:int32, [10, 20, 30, 40, 50], [1, 1, 1, 1, 1])

    list_col = %Array.List{
      length: 3,
      null_count: 0,
      validity: nil,
      offsets: Buffer.pack_int32_offsets([2, 0, 3]),
      values: inner
    }

    round_trip(%RecordBatch{schema: schema, length: 3, columns: [list_col]})
  end

  test "Struct<Int32, Utf8>" do
    schema = %Schema{
      fields: [
        %Field{
          name: "s",
          type: %Type.Struct{},
          nullable: true,
          children: [
            %Field{name: "n", type: %Type.Int{bit_width: 32, signed: true}, nullable: false},
            %Field{name: "name", type: %Type.Utf8{}, nullable: true}
          ]
        }
      ]
    }

    int_child = encoded_array(:int32, [1, 2], [1, 1])
    utf_child = encoded_array(:utf8, ["foo", "barbar"])

    struct_col = %Array.Struct{
      length: 2,
      null_count: 0,
      validity: nil,
      children: [int_child, utf_child]
    }

    round_trip(%RecordBatch{schema: schema, length: 2, columns: [struct_col]})
  end

  test "FixedSizeBinary" do
    schema = %Schema{
      fields: [
        %Field{name: "f", type: %Type.FixedSizeBinary{byte_width: 3}, nullable: true}
      ]
    }

    column = %Array.FixedSizeBinary{
      byte_width: 3,
      length: 2,
      null_count: 0,
      validity: nil,
      values: <<0xDE, 0xAD, 0xBE, 0xCA, 0xFE, 0xBA>>
    }

    round_trip(%RecordBatch{schema: schema, length: 2, columns: [column]})
  end

  test "Decimal128" do
    schema = %Schema{
      fields: [
        %Field{
          name: "d",
          type: %Type.Decimal{bit_width: 128, precision: 18, scale: 4},
          nullable: true
        }
      ]
    }

    values =
      [12_345, -67_890, 0]
      |> Enum.reduce(<<>>, fn v, acc -> <<acc::binary, v::little-signed-128>> end)

    column = %Array.Decimal128{
      precision: 18,
      scale: 4,
      length: 3,
      null_count: 0,
      validity: nil,
      values: values
    }

    round_trip(%RecordBatch{schema: schema, length: 3, columns: [column]})
  end
end
