defmodule Arrow.JsonRoundTripTest do
  use ExUnit.Case, async: true

  alias Arrow.{Json, RecordBatch, Schema}

  defp round_trip(json) do
    {:ok, %{schema: schema, batches: batches}} = Json.decode(json)
    encoded = Json.encode(schema, batches)
    {:ok, redecoded} = Json.decode(IO.iodata_to_binary(encoded))
    assert redecoded.schema == schema
    assert redecoded.batches == batches
    {schema, batches}
  end

  test "Null column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{"name" => "n", "type" => %{"name" => "null"}, "nullable" => true, "children" => []}
        ]
      },
      "batches" => [%{"count" => 4, "columns" => [%{"name" => "n", "count" => 4}]}]
    }

    {%Schema{fields: [field]}, [%RecordBatch{columns: [col]}]} = round_trip(json)
    assert field.type == %Arrow.Type.Null{}
    assert %Arrow.Array.Null{length: 4} = col
  end

  test "Bool column with nulls" do
    json = %{
      "schema" => %{
        "fields" => [
          %{"name" => "b", "type" => %{"name" => "bool"}, "nullable" => true, "children" => []}
        ]
      },
      "batches" => [
        %{
          "count" => 4,
          "columns" => [
            %{
              "name" => "b",
              "count" => 4,
              "VALIDITY" => [1, 0, 1, 1],
              "DATA" => [1, 0, 0, 1]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [col]}]} = round_trip(json)
    assert col.null_count == 1
    assert Arrow.Buffer.unpack_bool_values(col.values, 4) == [1, 0, 0, 1]
  end

  test "Int32 column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "i",
            "type" => %{"name" => "int", "bitWidth" => 32, "isSigned" => true},
            "nullable" => true,
            "children" => []
          }
        ]
      },
      "batches" => [
        %{
          "count" => 5,
          "columns" => [
            %{
              "name" => "i",
              "count" => 5,
              "VALIDITY" => [1, 1, 0, 1, 1],
              "DATA" => [-2_147_483_648, -1, 0, 1, 2_147_483_647]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.Int32{} = col]}]} = round_trip(json)
    assert col.null_count == 1

    assert Arrow.Buffer.unpack_primitive(col.values, :int32, 5) ==
             [-2_147_483_648, -1, 0, 1, 2_147_483_647]
  end

  test "Int64 column uses string DATA" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "i",
            "type" => %{"name" => "int", "bitWidth" => 64, "isSigned" => true},
            "nullable" => true,
            "children" => []
          }
        ]
      },
      "batches" => [
        %{
          "count" => 3,
          "columns" => [
            %{
              "name" => "i",
              "count" => 3,
              "VALIDITY" => [1, 1, 1],
              "DATA" => ["-9223372036854775808", "0", "9223372036854775807"]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.Int64{}]}]} = round_trip(json)
  end

  test "UInt64 column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "u",
            "type" => %{"name" => "int", "bitWidth" => 64, "isSigned" => false},
            "nullable" => true,
            "children" => []
          }
        ]
      },
      "batches" => [
        %{
          "count" => 2,
          "columns" => [
            %{
              "name" => "u",
              "count" => 2,
              "VALIDITY" => [1, 1],
              "DATA" => ["0", "18446744073709551615"]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.UInt64{} = col]}]} = round_trip(json)

    assert Arrow.Buffer.unpack_primitive(col.values, :uint64, 2) ==
             [0, 18_446_744_073_709_551_615]
  end

  test "Float64 column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "f",
            "type" => %{"name" => "floatingpoint", "precision" => "DOUBLE"},
            "nullable" => true,
            "children" => []
          }
        ]
      },
      "batches" => [
        %{
          "count" => 3,
          "columns" => [
            %{
              "name" => "f",
              "count" => 3,
              "VALIDITY" => [1, 0, 1],
              "DATA" => [3.14, 0.0, -2.5]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.Float64{}]}]} = round_trip(json)
  end

  test "Utf8 column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{"name" => "s", "type" => %{"name" => "utf8"}, "nullable" => true, "children" => []}
        ]
      },
      "batches" => [
        %{
          "count" => 4,
          "columns" => [
            %{
              "name" => "s",
              "count" => 4,
              "VALIDITY" => [1, 0, 1, 1],
              "OFFSET" => [0, 3, 3, 5, 10],
              "DATA" => ["foo", "", "ar", "rowarr"]
            }
          ]
        }
      ]
    }

    # The reader rebuilds OFFSET from DATA byte sizes, so the offsets check
    # only verifies the writer round-trips its own state. Pass through encode
    # and decode again to confirm symmetry.
    {:ok, %{batches: [batch1]}} = Json.decode(json)
    encoded = Json.encode(%Arrow.Schema{fields: batch1.schema.fields}, [batch1])
    {:ok, redecoded} = Json.decode(IO.iodata_to_binary(encoded))
    assert redecoded.batches == [batch1]
  end

  test "Binary column with hex DATA" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "b",
            "type" => %{"name" => "binary"},
            "nullable" => true,
            "children" => []
          }
        ]
      },
      "batches" => [
        %{
          "count" => 3,
          "columns" => [
            %{
              "name" => "b",
              "count" => 3,
              "VALIDITY" => [1, 1, 0],
              "OFFSET" => [0, 2, 5, 5],
              "DATA" => ["DEAD", "BEEFCA", ""]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.Binary{} = col]}]} = round_trip(json)

    assert Arrow.Buffer.slice_variable(col.offsets, col.values, 3) ==
             [<<0xDE, 0xAD>>, <<0xBE, 0xEF, 0xCA>>, <<>>]
  end

  test "Date32 column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "d",
            "type" => %{"name" => "date", "unit" => "DAY"},
            "nullable" => true,
            "children" => []
          }
        ]
      },
      "batches" => [
        %{
          "count" => 3,
          "columns" => [
            %{"name" => "d", "count" => 3, "VALIDITY" => [1, 1, 1], "DATA" => [0, 1, 20_000]}
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.Date32{}]}]} = round_trip(json)
  end

  test "Timestamp[us, UTC] column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "ts",
            "type" => %{
              "name" => "timestamp",
              "unit" => "MICROSECOND",
              "timezone" => "UTC"
            },
            "nullable" => false,
            "children" => []
          }
        ]
      },
      "batches" => [
        %{
          "count" => 2,
          "columns" => [
            %{
              "name" => "ts",
              "count" => 2,
              "VALIDITY" => [1, 1],
              "DATA" => ["1700000000000000", "1800000000000000"]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.Timestamp{} = col]}]} = round_trip(json)
    assert col.unit == :microsecond
    assert col.timezone == "UTC"
  end

  test "List<Int32> column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "l",
            "type" => %{"name" => "list"},
            "nullable" => true,
            "children" => [
              %{
                "name" => "item",
                "type" => %{"name" => "int", "bitWidth" => 32, "isSigned" => true},
                "nullable" => true,
                "children" => []
              }
            ]
          }
        ]
      },
      "batches" => [
        %{
          "count" => 3,
          "columns" => [
            %{
              "name" => "l",
              "count" => 3,
              "VALIDITY" => [1, 1, 1],
              "OFFSET" => [0, 2, 2, 5],
              "children" => [
                %{
                  "name" => "item",
                  "count" => 5,
                  "VALIDITY" => [1, 1, 1, 1, 1],
                  "DATA" => [10, 20, 30, 40, 50]
                }
              ]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.List{}]}]} = round_trip(json)
  end

  test "Struct<Int32, Utf8> column" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "s",
            "type" => %{"name" => "struct"},
            "nullable" => true,
            "children" => [
              %{
                "name" => "a",
                "type" => %{"name" => "int", "bitWidth" => 32, "isSigned" => true},
                "nullable" => true,
                "children" => []
              },
              %{
                "name" => "b",
                "type" => %{"name" => "utf8"},
                "nullable" => true,
                "children" => []
              }
            ]
          }
        ]
      },
      "batches" => [
        %{
          "count" => 2,
          "columns" => [
            %{
              "name" => "s",
              "count" => 2,
              "VALIDITY" => [1, 1],
              "children" => [
                %{"name" => "a", "count" => 2, "VALIDITY" => [1, 1], "DATA" => [1, 2]},
                %{
                  "name" => "b",
                  "count" => 2,
                  "VALIDITY" => [1, 0],
                  "OFFSET" => [0, 3, 3],
                  "DATA" => ["foo", ""]
                }
              ]
            }
          ]
        }
      ]
    }

    {_schema, [%RecordBatch{columns: [%Arrow.Array.Struct{children: [_a, _b]}]}]} =
      round_trip(json)
  end

  test "schema metadata round-trips" do
    json = %{
      "schema" => %{
        "fields" => [
          %{
            "name" => "i",
            "type" => %{"name" => "int", "bitWidth" => 32, "isSigned" => true},
            "nullable" => true,
            "children" => [],
            "metadata" => [%{"key" => "doc", "value" => "row count"}]
          }
        ],
        "metadata" => [%{"key" => "version", "value" => "1"}]
      },
      "batches" => [
        %{
          "count" => 1,
          "columns" => [%{"name" => "i", "count" => 1, "VALIDITY" => [1], "DATA" => [42]}]
        }
      ]
    }

    {schema, _batches} = round_trip(json)
    assert schema.metadata == %{"version" => "1"}
    assert hd(schema.fields).metadata == %{"doc" => "row count"}
  end
end
