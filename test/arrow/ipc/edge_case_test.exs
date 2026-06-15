# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.Ipc.EdgeCaseTest do
  use ExUnit.Case, async: true

  alias Arrow.{Array, Buffer, Field, Logical, RecordBatch, Schema, Type}
  alias Arrow.Ipc.File, as: IpcFile
  alias Arrow.Ipc.Stream

  @formats [
    {"stream", &Stream.encode/3, &Stream.decode/1},
    {"file", &IpcFile.encode/3, &IpcFile.decode/1}
  ]

  test "zero-row batch round-trips" do
    schema = %Schema{
      fields: [
        %Field{name: "n", type: %Type.Int{bit_width: 32, signed: true}, nullable: false},
        %Field{name: "s", type: %Type.Utf8{}, nullable: false}
      ]
    }

    batch = %RecordBatch{
      schema: schema,
      length: 0,
      columns: [
        %Array.Int32{length: 0, null_count: 0, values: <<>>},
        %Array.Utf8{
          length: 0,
          null_count: 0,
          offsets: Buffer.pack_int32_offsets([]),
          values: <<>>
        }
      ]
    }

    for {label, encode, decode} <- @formats do
      {:ok, decoded} = decode.(encode.(schema, [batch], %{}))

      assert [d] = decoded.batches, "#{label}: expected one batch"
      assert d.length == 0
      assert Logical.batches_equal?(d, batch), "#{label}: zero-row batch diverged"
    end
  end

  test "all-null columns round-trip with null_count preserved" do
    schema = %Schema{
      fields: [
        %Field{name: "n", type: %Type.Int{bit_width: 32, signed: true}, nullable: true},
        %Field{name: "s", type: %Type.Utf8{}, nullable: true}
      ]
    }

    {validity, 3} = Buffer.pack_validity([0, 0, 0])

    batch = %RecordBatch{
      schema: schema,
      length: 3,
      columns: [
        %Array.Int32{
          length: 3,
          null_count: 3,
          validity: validity,
          values: Buffer.pack_primitive([0, 0, 0], :int32)
        },
        %Array.Utf8{
          length: 3,
          null_count: 3,
          validity: validity,
          offsets: Buffer.pack_int32_offsets([0, 0, 0]),
          values: <<>>
        }
      ]
    }

    for {label, encode, decode} <- @formats do
      {:ok, decoded} = decode.(encode.(schema, [batch], %{}))

      assert [d] = decoded.batches, "#{label}: expected one batch"
      assert Enum.map(d.columns, & &1.null_count) == [3, 3]

      assert Enum.map(d.columns, &Logical.to_list(&1, %{})) ==
               [[nil, nil, nil], [nil, nil, nil]],
             "#{label}: all-null columns diverged"
    end
  end

  test "dictionary-encoded column round-trips through DictionaryBatch messages" do
    schema = %Schema{
      fields: [
        %Field{
          name: "d",
          type: %Type.Utf8{},
          nullable: true,
          dictionary: %Type.DictionaryEncoding{
            id: 7,
            index_type: %Type.Int{bit_width: 8, signed: true},
            is_ordered: false
          }
        }
      ]
    }

    {validity, 1} = Buffer.pack_validity([1, 1, 0, 1])

    column = %Array.Dictionary{
      dictionary_id: 7,
      indices: %Array.Int8{
        length: 4,
        null_count: 1,
        validity: validity,
        values: Buffer.pack_primitive([0, 1, 0, 0], :int8)
      }
    }

    dictionaries = %{
      7 => %Array.Utf8{
        length: 2,
        null_count: 0,
        offsets: Buffer.pack_int32_offsets([1, 1]),
        values: "xy"
      }
    }

    batch = %RecordBatch{schema: schema, length: 4, columns: [column]}

    for {label, encode, decode} <- @formats do
      {:ok, decoded} = decode.(encode.(schema, [batch], dictionaries))

      assert map_size(decoded.dictionaries) == 1, "#{label}: dictionary batch lost"

      assert Logical.payloads_equivalent?(
               decoded,
               %{schema: schema, dictionaries: dictionaries, batches: [batch]}
             ),
             "#{label}: dictionary payload diverged"

      assert [d] = decoded.batches

      assert Enum.map(d.columns, &Logical.to_list(&1, decoded.dictionaries)) ==
               [["x", "y", nil, "x"]],
             "#{label}: dictionary indices resolved to wrong values"
    end
  end
end
