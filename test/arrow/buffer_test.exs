defmodule Arrow.BufferTest do
  use ExUnit.Case, async: true
  doctest Arrow.Buffer

  alias Arrow.Buffer

  describe "validity bitmaps" do
    test "round-trip preserves valid/null pattern" do
      for flags <- [
            [],
            [1],
            [0],
            [1, 0, 1, 1, 0],
            [1, 1, 1, 1, 1, 1, 1, 1],
            [0, 0, 0, 0, 0, 0, 0, 0, 1, 0],
            for(_ <- 1..17, do: 1)
          ] do
        {bitmap, null_count} = Buffer.pack_validity(flags)
        assert Buffer.unpack_validity(bitmap, length(flags)) == flags
        assert null_count == Enum.count(flags, &(&1 == 0))
      end
    end

    test "accepts boolean input" do
      {bitmap, null_count} = Buffer.pack_validity([true, false, true])
      assert null_count == 1
      assert Buffer.unpack_validity(bitmap, 3) == [1, 0, 1]
    end

    test "nil bitmap decodes as all-valid" do
      assert Buffer.unpack_validity(nil, 4) == [1, 1, 1, 1]
    end
  end

  describe "primitive packing" do
    test "round-trips every Tier-1 primitive kind" do
      cases = [
        {:int8, [-128, -1, 0, 1, 127]},
        {:int16, [-32_768, 0, 32_767]},
        {:int32, [-2_147_483_648, -1, 0, 1, 2_147_483_647]},
        {:int64, [-9_223_372_036_854_775_808, 0, 9_223_372_036_854_775_807]},
        {:uint8, [0, 255]},
        {:uint16, [0, 65_535]},
        {:uint32, [0, 4_294_967_295]},
        {:uint64, [0, 18_446_744_073_709_551_615]},
        {:float64, [-1.5, 0.0, 3.14159]}
      ]

      for {kind, values} <- cases do
        encoded = Buffer.pack_primitive(values, kind)
        assert Buffer.unpack_primitive(encoded, kind, length(values)) == values
      end
    end

    test "float32 round-trips within float32 precision" do
      values = [0.0, 1.0, -2.0, 0.5]
      encoded = Buffer.pack_primitive(values, :float32)
      decoded = Buffer.unpack_primitive(encoded, :float32, length(values))

      for {a, b} <- Enum.zip(values, decoded) do
        assert_in_delta a, b, 1.0e-6
      end
    end
  end

  describe "variable offsets" do
    test "offsets are cumulative starting at zero" do
      offsets = Buffer.pack_int32_offsets([3, 0, 2, 5])
      assert Buffer.unpack_int32_offsets(offsets, 4) == [0, 3, 3, 5, 10]
    end

    test "slice_variable reconstructs the original byte strings" do
      strings = ["abc", "", "de", "fghij"]
      lengths = Enum.map(strings, &byte_size/1)
      offsets = Buffer.pack_int32_offsets(lengths)
      values = IO.iodata_to_binary(strings)

      assert Buffer.slice_variable(offsets, values, length(strings)) == strings
    end
  end

  describe "alignment" do
    test "padding rounds up to multiples of 8" do
      assert Buffer.padding_size(0) == 0
      assert Buffer.padding_size(1) == 7
      assert Buffer.padding_size(7) == 1
      assert Buffer.padding_size(8) == 0
      assert Buffer.padding_size(9) == 7
    end

    test "pad_to_alignment appends zero bytes" do
      assert Buffer.pad_to_alignment(<<1, 2, 3>>) == <<1, 2, 3, 0, 0, 0, 0, 0>>
      assert Buffer.pad_to_alignment(<<0::64>>) == <<0::64>>
    end
  end
end
