# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.HardeningTest do
  @moduledoc """
  Regression tests for hardening fixes in the data-model / JSON /
  comparator layer: dictionary index bounds-checking, padded-buffer
  tolerance, JSON Bool representation, FixedSizeBinary slot bounding,
  and dictionary-permutation equivalence.
  """

  use ExUnit.Case, async: true

  alias Arrow.{Array, Buffer, Field, Json, Logical, RecordBatch, Schema, Type}

  defp int32(values) do
    %Array.Int32{
      length: length(values),
      null_count: 0,
      validity: nil,
      values: Buffer.pack_primitive(values, :int32)
    }
  end

  defp utf8(strings) do
    %Array.Utf8{
      length: length(strings),
      null_count: 0,
      validity: nil,
      offsets: Buffer.pack_int32_offsets(Enum.map(strings, &byte_size/1)),
      values: IO.iodata_to_binary(strings)
    }
  end

  describe "dictionary index bounds-checking" do
    test "out-of-range index raises ArgumentError" do
      array = %Array.Dictionary{dictionary_id: 0, indices: int32([0, 3])}
      dicts = %{0 => utf8(["a", "b", "c"])}

      assert_raise ArgumentError,
                   "dictionary index 3 out of bounds for dictionary id 0 of length 3",
                   fn -> Logical.to_list(array, dicts) end
    end

    test "negative index raises ArgumentError" do
      array = %Array.Dictionary{dictionary_id: 0, indices: int32([-1])}
      dicts = %{0 => utf8(["a", "b", "c"])}

      assert_raise ArgumentError,
                   "dictionary index -1 out of bounds for dictionary id 0 of length 3",
                   fn -> Logical.to_list(array, dicts) end
    end

    test "in-range indices still resolve" do
      array = %Array.Dictionary{dictionary_id: 0, indices: int32([2, 0])}
      dicts = %{0 => utf8(["a", "b", "c"])}

      assert Logical.to_list(array, dicts) == ["c", "a"]
    end
  end

  describe "unpack_primitive/3 at length 0" do
    test "accepts a padded zero-length buffer" do
      padded = <<0, 0, 0, 0, 0, 0, 0, 0>>
      assert Buffer.unpack_primitive(padded, :int32, 0) == []
    end

    test "still accepts the empty buffer" do
      assert Buffer.unpack_primitive(<<>>, :int32, 0) == []
    end
  end

  describe "Bool JSON representation" do
    test "writer emits JSON true/false, not 0/1" do
      schema = %Schema{fields: [%Field{name: "b", type: %Type.Bool{}}]}

      batch = %RecordBatch{
        schema: schema,
        length: 3,
        columns: [
          %Array.Bool{
            length: 3,
            null_count: 0,
            validity: nil,
            values: Buffer.pack_bool_values([1, 0, 1])
          }
        ]
      }

      %{"batches" => [%{"columns" => [col]}]} = Json.Writer.write(schema, [batch])
      assert col["DATA"] == [true, false, true]
    end

    test "reader accepts boolean DATA" do
      doc = %{
        "schema" => %{
          "fields" => [
            %{"name" => "b", "type" => %{"name" => "bool"}, "nullable" => true, "children" => []}
          ]
        },
        "batches" => [
          %{
            "count" => 3,
            "columns" => [
              %{
                "name" => "b",
                "count" => 3,
                "VALIDITY" => [1, 1, 1],
                "DATA" => [true, false, true]
              }
            ]
          }
        ]
      }

      assert {:ok, %{batches: [%RecordBatch{columns: [col]}]}} = Json.decode(doc)
      assert Buffer.unpack_bool_values(col.values, 3) == [1, 0, 1]
    end
  end

  describe "FixedSizeBinary JSON writer" do
    test "padded values buffer emits exactly a.length DATA slots" do
      schema = %Schema{
        fields: [%Field{name: "f", type: %Type.FixedSizeBinary{byte_width: 2}}]
      }

      # Two 2-byte slots followed by 4 bytes of alignment padding: the
      # writer must not turn the padding into phantom slots.
      padded_values = <<1, 2, 3, 4, 0, 0, 0, 0>>

      batch = %RecordBatch{
        schema: schema,
        length: 2,
        columns: [
          %Array.FixedSizeBinary{
            byte_width: 2,
            length: 2,
            null_count: 0,
            validity: nil,
            values: padded_values
          }
        ]
      }

      %{"batches" => [%{"columns" => [col]}]} = Json.Writer.write(schema, [batch])
      assert col["DATA"] == ["0102", "0304"]
    end
  end

  describe "payloads_equivalent?/2 with permuted dictionaries" do
    test "permuted dictionary plus correspondingly permuted indices compare equal" do
      make_schema = fn id ->
        %Schema{
          fields: [
            %Field{
              name: "s",
              type: %Type.Utf8{},
              dictionary: %Type.DictionaryEncoding{
                id: id,
                index_type: %Type.Int{bit_width: 32, signed: true}
              }
            }
          ]
        }
      end

      schema_a = make_schema.(0)
      schema_b = make_schema.(0)

      # Both payloads logically encode ["a", "b", "c"], but B's
      # dictionary is permuted (and its indices permuted to match).
      dicts_a = %{0 => utf8(["a", "b", "c"])}
      dicts_b = %{0 => utf8(["c", "b", "a"])}

      batch_a = %RecordBatch{
        schema: schema_a,
        length: 3,
        columns: [%Array.Dictionary{dictionary_id: 0, indices: int32([0, 1, 2])}]
      }

      batch_b = %RecordBatch{
        schema: schema_b,
        length: 3,
        columns: [%Array.Dictionary{dictionary_id: 0, indices: int32([2, 1, 0])}]
      }

      payload_a = %{schema: schema_a, dictionaries: dicts_a, batches: [batch_a]}
      payload_b = %{schema: schema_b, dictionaries: dicts_b, batches: [batch_b]}

      assert Logical.payloads_equivalent?(payload_a, payload_b)
    end

    test "still unequal when resolved values differ" do
      schema = %Schema{
        fields: [
          %Field{
            name: "s",
            type: %Type.Utf8{},
            dictionary: %Type.DictionaryEncoding{
              id: 0,
              index_type: %Type.Int{bit_width: 32, signed: true}
            }
          }
        ]
      }

      batch = fn indices ->
        %RecordBatch{
          schema: schema,
          length: 2,
          columns: [%Array.Dictionary{dictionary_id: 0, indices: int32(indices)}]
        }
      end

      payload_a = %{
        schema: schema,
        dictionaries: %{0 => utf8(["a", "b"])},
        batches: [batch.([0, 1])]
      }

      payload_b = %{
        schema: schema,
        dictionaries: %{0 => utf8(["a", "b"])},
        batches: [batch.([1, 0])]
      }

      refute Logical.payloads_equivalent?(payload_a, payload_b)
    end

    test "unequal when a dictionary id is unresolvable in one registry" do
      schema = %Schema{
        fields: [
          %Field{
            name: "s",
            type: %Type.Utf8{},
            dictionary: %Type.DictionaryEncoding{
              id: 0,
              index_type: %Type.Int{bit_width: 32, signed: true}
            }
          }
        ]
      }

      payload_a = %{schema: schema, dictionaries: %{0 => utf8(["a"])}, batches: []}
      payload_b = %{schema: schema, dictionaries: %{}, batches: []}

      refute Logical.payloads_equivalent?(payload_a, payload_b)
    end
  end
end
