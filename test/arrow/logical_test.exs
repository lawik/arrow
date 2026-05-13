defmodule Arrow.LogicalTest do
  use ExUnit.Case, async: true

  alias Arrow.{Array, Buffer, Logical}

  defp int32(values, validity_flags \\ nil) do
    flags = validity_flags || List.duplicate(1, length(values))
    {bitmap, null_count} = Buffer.pack_validity(flags)
    validity = if null_count == 0, do: nil, else: bitmap

    %Array.Int32{
      length: length(values),
      null_count: null_count,
      validity: validity,
      values: Buffer.pack_primitive(values, :int32)
    }
  end

  defp utf8(strings, validity_flags \\ nil) do
    flags = validity_flags || List.duplicate(1, length(strings))
    {bitmap, null_count} = Buffer.pack_validity(flags)
    validity = if null_count == 0, do: nil, else: bitmap
    lengths = Enum.map(strings, &byte_size/1)

    %Array.Utf8{
      length: length(strings),
      null_count: null_count,
      validity: validity,
      offsets: Buffer.pack_int32_offsets(lengths),
      values: IO.iodata_to_binary(strings)
    }
  end

  describe "to_list/1" do
    test "Null produces a list of nils" do
      assert Logical.to_list(%Array.Null{length: 4}) == [nil, nil, nil, nil]
    end

    test "primitive ints with nulls" do
      assert Logical.to_list(int32([10, 20, 0, 40], [1, 1, 0, 1])) == [10, 20, nil, 40]
    end

    test "Utf8 with nulls" do
      assert Logical.to_list(utf8(["foo", "", "bar"], [1, 0, 1])) == ["foo", nil, "bar"]
    end

    test "Bool" do
      values = Buffer.pack_bool_values([1, 0, 1, 1])
      {bitmap, _} = Buffer.pack_validity([1, 1, 0, 1])

      a = %Array.Bool{length: 4, null_count: 1, validity: bitmap, values: values}
      assert Logical.to_list(a) == [true, false, nil, true]
    end

    test "List<Int32>" do
      child = int32([10, 20, 30, 40, 50])

      list = %Array.List{
        length: 3,
        null_count: 0,
        validity: nil,
        offsets: Buffer.pack_int32_offsets([2, 0, 3]),
        values: child
      }

      assert Logical.to_list(list) == [[10, 20], [], [30, 40, 50]]
    end

    test "Struct<Int32, Utf8>" do
      a = %Array.Struct{
        length: 3,
        null_count: 0,
        validity: nil,
        children: [int32([1, 2, 3]), utf8(["a", "b", "c"])]
      }

      assert Logical.to_list(a) == [[1, "a"], [2, "b"], [3, "c"]]
    end

    test "Struct nullability masks the whole row" do
      {bitmap, nc} = Buffer.pack_validity([1, 0, 1])

      a = %Array.Struct{
        length: 3,
        null_count: nc,
        validity: bitmap,
        children: [int32([1, 99, 3]), utf8(["a", "junk", "c"])]
      }

      assert Logical.to_list(a) == [[1, "a"], nil, [3, "c"]]
    end

    test "FixedSizeList<Int32, 2>" do
      a = %Array.FixedSizeList{
        list_size: 2,
        length: 3,
        null_count: 0,
        validity: nil,
        values: int32([1, 2, 3, 4, 5, 6])
      }

      assert Logical.to_list(a) == [[1, 2], [3, 4], [5, 6]]
    end

    test "Map<Utf8, Int32>" do
      entries = %Array.Struct{
        length: 4,
        null_count: 0,
        validity: nil,
        children: [utf8(["a", "b", "c", "d"]), int32([1, 2, 3, 4])]
      }

      m = %Array.Map{
        keys_sorted: false,
        length: 2,
        null_count: 0,
        validity: nil,
        offsets: Buffer.pack_int32_offsets([2, 2]),
        values: entries
      }

      assert Logical.to_list(m) == [[{"a", 1}, {"b", 2}], [{"c", 3}, {"d", 4}]]
    end
  end

  describe "equality" do
    test "two arrays equal when value bytes differ only at null positions" do
      a1 = int32([10, 99, 30], [1, 0, 1])
      # Same logical content but with 0 in the null slot — different bytes,
      # same logical content.
      a2 = int32([10, 0, 30], [1, 0, 1])

      refute a1 == a2
      assert Logical.arrays_equal?(a1, a2)
    end

    test "different non-null values are not equal" do
      a1 = int32([10, 20, 30])
      a2 = int32([10, 99, 30])

      refute Logical.arrays_equal?(a1, a2)
    end

    test "batches_equal?" do
      schema = %Arrow.Schema{
        fields: [
          %Arrow.Field{
            name: "x",
            type: %Arrow.Type.Int{bit_width: 32, signed: true},
            nullable: true
          }
        ]
      }

      a = %Arrow.RecordBatch{schema: schema, length: 3, columns: [int32([1, 99, 3], [1, 0, 1])]}
      b = %Arrow.RecordBatch{schema: schema, length: 3, columns: [int32([1, 0, 3], [1, 0, 1])]}

      assert Logical.batches_equal?(a, b)
    end
  end
end
