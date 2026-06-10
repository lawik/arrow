defmodule Arrow.GoldenTest do
  @moduledoc """
  External ground truth for the always-run suite.

  Decodes IPC bytes produced by pyarrow (the Arrow C++ reference
  implementation) and asserts schemas and per-slot logical values against
  literals copied from the generator script. Unlike the encode → decode
  round-trip tests, a symmetric encode/decode bug cannot pass here: the
  bytes come from a foreign producer.

  Regenerate the files with `test/golden/generate.py` (see its header).
  Dates are days since epoch, timestamps epoch microseconds, decimals
  unscaled integers — `Arrow.Logical.to_list/2` does not apply units.
  """

  use ExUnit.Case, async: true

  alias Arrow.{Logical, Type}
  alias Arrow.Ipc.File, as: IpcFile
  alias Arrow.Ipc.Stream

  @golden_names ["primitives", "nested", "dictionary", "empty"]

  defp decode!(name, ext) do
    bin = File.read!(Path.join([__DIR__, "..", "golden", name <> ext]))

    {:ok, payload} =
      case ext do
        ".stream" -> Stream.decode(bin)
        ".arrow" -> IpcFile.decode(bin)
      end

    payload
  end

  defp columns_as_lists(%{batches: [batch], dictionaries: dicts}) do
    Enum.map(batch.columns, &Logical.to_list(&1, dicts))
  end

  for ext <- [".stream", ".arrow"] do
    describe "pyarrow-produced #{ext}" do
      test "primitives: schema and values match the generator literals" do
        payload = decode!("primitives", unquote(ext))

        assert Enum.map(payload.schema.fields, &{&1.name, &1.type}) == [
                 {"i32", %Type.Int{bit_width: 32, signed: true}},
                 {"u8", %Type.Int{bit_width: 8, signed: false}},
                 {"f64", %Type.FloatingPoint{precision: :double}},
                 {"b", %Type.Bool{}},
                 {"s", %Type.Utf8{}},
                 {"bin", %Type.Binary{}},
                 {"d32", %Type.Date{unit: :day}},
                 {"ts_us", %Type.Timestamp{unit: :microsecond, timezone: "UTC"}},
                 {"dec", %Type.Decimal{bit_width: 128, precision: 10, scale: 2}}
               ]

        assert columns_as_lists(payload) == [
                 [1, nil, 3, -2_147_483_648, 2_147_483_647],
                 [0, 255, nil, 7, 1],
                 [1.5, nil, -0.25, 1.0e308, 0.0],
                 [true, nil, false, true, false],
                 ["", nil, "hé", "arrow", "z"],
                 [<<0, 1>>, nil, <<>>, <<0xFF, 0>>, "abc"],
                 [0, 1, nil, 19_000, -1],
                 [0, 1_700_000_000_000_000, nil, -1, 86_400_000_000],
                 [123, nil, -9_999_999_999, 1, 0]
               ]
      end

      test "nested: list, struct, and map values match the generator literals" do
        payload = decode!("nested", unquote(ext))

        assert Enum.map(payload.schema.fields, &{&1.name, &1.type}) == [
                 {"l", %Type.List{}},
                 {"st", %Type.Struct{}},
                 {"m", %Type.Map{keys_sorted: false}}
               ]

        [_, st_field, _] = payload.schema.fields
        assert Enum.map(st_field.children, & &1.name) == ["a", "b"]

        assert columns_as_lists(payload) == [
                 [[1, 2, 3], [], nil, [nil, 5]],
                 [[1, "x"], nil, [nil, "y"], [4, ""]],
                 [[{"k1", 1}, {"k2", 2}], [], nil, [{"k3", nil}]]
               ]
      end

      test "dictionary: DictionaryBatch resolves to the generator literals" do
        payload = decode!("dictionary", unquote(ext))

        assert [field] = payload.schema.fields
        assert field.type == %Type.Utf8{}

        assert %Type.DictionaryEncoding{
                 index_type: %Type.Int{bit_width: 8, signed: true},
                 is_ordered: false
               } = field.dictionary

        assert [{_id, dict_values}] = Map.to_list(payload.dictionaries)
        assert Logical.to_list(dict_values, %{}) == ["a", "b", "c"]

        assert columns_as_lists(payload) == [["a", "b", nil, "a", "c", "b"]]
      end

      test "empty: a zero-row batch decodes with zero-length columns" do
        payload = decode!("empty", unquote(ext))

        assert [batch] = payload.batches
        assert batch.length == 0
        assert columns_as_lists(payload) == [[], []]
      end
    end
  end

  test "stream and file decodes of the same data agree" do
    for name <- @golden_names do
      assert Logical.payloads_equivalent?(decode!(name, ".stream"), decode!(name, ".arrow")),
             "stream/file divergence for #{name}"
    end
  end
end
