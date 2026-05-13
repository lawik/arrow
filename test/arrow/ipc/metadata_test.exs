defmodule Arrow.Ipc.MetadataTest do
  use ExUnit.Case, async: true

  alias Arrow.Ipc.Metadata
  alias Arrow.{Field, Schema, Type}

  defp round_trip(%Schema{} = schema) do
    binary = Metadata.encode_schema(schema)
    assert is_binary(binary)
    assert byte_size(binary) > 0
    {:ok, decoded} = Metadata.decode_schema(binary)
    assert decoded == schema
    binary
  end

  describe "Tier 1 types round-trip through FB" do
    test "Null, Bool, primitive integers, floats" do
      schema = %Schema{
        fields: [
          %Field{name: "n", type: %Type.Null{}, nullable: true},
          %Field{name: "b", type: %Type.Bool{}, nullable: true},
          %Field{name: "i8", type: %Type.Int{bit_width: 8, signed: true}, nullable: false},
          %Field{name: "i16", type: %Type.Int{bit_width: 16, signed: true}, nullable: false},
          %Field{name: "i32", type: %Type.Int{bit_width: 32, signed: true}, nullable: false},
          %Field{name: "i64", type: %Type.Int{bit_width: 64, signed: true}, nullable: false},
          %Field{name: "u8", type: %Type.Int{bit_width: 8, signed: false}, nullable: false},
          %Field{name: "u16", type: %Type.Int{bit_width: 16, signed: false}, nullable: false},
          %Field{name: "u32", type: %Type.Int{bit_width: 32, signed: false}, nullable: false},
          %Field{name: "u64", type: %Type.Int{bit_width: 64, signed: false}, nullable: false},
          %Field{name: "f32", type: %Type.FloatingPoint{precision: :single}, nullable: false},
          %Field{name: "f64", type: %Type.FloatingPoint{precision: :double}, nullable: false}
        ]
      }

      round_trip(schema)
    end

    test "Utf8, Binary" do
      schema = %Schema{
        fields: [
          %Field{name: "s", type: %Type.Utf8{}, nullable: true},
          %Field{name: "b", type: %Type.Binary{}, nullable: true}
        ]
      }

      round_trip(schema)
    end

    test "Date32, Date64, Timestamp with and without timezone" do
      schema = %Schema{
        fields: [
          %Field{name: "d32", type: %Type.Date{unit: :day}, nullable: true},
          %Field{name: "d64", type: %Type.Date{unit: :millisecond}, nullable: true},
          %Field{
            name: "ts_naive",
            type: %Type.Timestamp{unit: :microsecond, timezone: nil},
            nullable: false
          },
          %Field{
            name: "ts_utc",
            type: %Type.Timestamp{unit: :nanosecond, timezone: "UTC"},
            nullable: false
          }
        ]
      }

      round_trip(schema)
    end

    test "List of Int32" do
      schema = %Schema{
        fields: [
          %Field{
            name: "l",
            type: %Type.List{},
            nullable: true,
            children: [
              %Field{
                name: "item",
                type: %Type.Int{bit_width: 32, signed: true},
                nullable: true
              }
            ]
          }
        ]
      }

      round_trip(schema)
    end

    test "Struct of Int32 + Utf8" do
      schema = %Schema{
        fields: [
          %Field{
            name: "s",
            type: %Type.Struct{},
            nullable: true,
            children: [
              %Field{
                name: "n",
                type: %Type.Int{bit_width: 32, signed: true},
                nullable: false
              },
              %Field{name: "name", type: %Type.Utf8{}, nullable: true}
            ]
          }
        ]
      }

      round_trip(schema)
    end
  end

  describe "Tier 2 types round-trip through FB" do
    test "Time32, Time64" do
      schema = %Schema{
        fields: [
          %Field{name: "t32", type: %Type.Time{bit_width: 32, unit: :second}, nullable: true},
          %Field{name: "t64", type: %Type.Time{bit_width: 64, unit: :nanosecond}, nullable: true}
        ]
      }

      round_trip(schema)
    end

    test "Duration" do
      schema = %Schema{
        fields: [
          %Field{name: "d", type: %Type.Duration{unit: :microsecond}, nullable: false}
        ]
      }

      round_trip(schema)
    end

    test "FixedSizeBinary, FixedSizeList" do
      schema = %Schema{
        fields: [
          %Field{
            name: "fsb",
            type: %Type.FixedSizeBinary{byte_width: 16},
            nullable: true
          },
          %Field{
            name: "fsl",
            type: %Type.FixedSizeList{list_size: 4},
            nullable: true,
            children: [
              %Field{
                name: "item",
                type: %Type.Int{bit_width: 32, signed: true},
                nullable: false
              }
            ]
          }
        ]
      }

      round_trip(schema)
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

      round_trip(schema)
    end

    test "Map<Utf8, Int32>" do
      schema = %Schema{
        fields: [
          %Field{
            name: "m",
            type: %Type.Map{keys_sorted: false},
            nullable: true,
            children: [
              %Field{
                name: "entries",
                type: %Type.Struct{},
                nullable: false,
                children: [
                  %Field{name: "key", type: %Type.Utf8{}, nullable: false},
                  %Field{
                    name: "value",
                    type: %Type.Int{bit_width: 32, signed: true},
                    nullable: true
                  }
                ]
              }
            ]
          }
        ]
      }

      round_trip(schema)
    end
  end

  describe "metadata" do
    test "schema-level metadata round-trips" do
      schema = %Schema{
        fields: [
          %Field{name: "x", type: %Type.Int{bit_width: 32, signed: true}, nullable: false}
        ],
        metadata: %{"version" => "1", "author" => "test"}
      }

      round_trip(schema)
    end

    test "field-level metadata round-trips" do
      schema = %Schema{
        fields: [
          %Field{
            name: "x",
            type: %Type.Int{bit_width: 32, signed: true},
            nullable: false,
            metadata: %{"unit" => "rows"}
          }
        ]
      }

      round_trip(schema)
    end
  end
end
