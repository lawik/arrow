defmodule Arrow.Ipc.Flatbuf.Type do
  @moduledoc "Generated from FlatBuffers union Arrow.Ipc.Flatbuf.Type. Do not edit."

  @type t ::
          nil
          | {:Null, Arrow.Ipc.Flatbuf.Null.t()}
          | {:Int, Arrow.Ipc.Flatbuf.Int.t()}
          | {:FloatingPoint, Arrow.Ipc.Flatbuf.FloatingPoint.t()}
          | {:Binary, Arrow.Ipc.Flatbuf.Binary.t()}
          | {:Utf8, Arrow.Ipc.Flatbuf.Utf8.t()}
          | {:Bool, Arrow.Ipc.Flatbuf.Bool.t()}
          | {:Decimal, Arrow.Ipc.Flatbuf.Decimal.t()}
          | {:Date, Arrow.Ipc.Flatbuf.Date.t()}
          | {:Time, Arrow.Ipc.Flatbuf.Time.t()}
          | {:Timestamp, Arrow.Ipc.Flatbuf.Timestamp.t()}
          | {:Interval, Arrow.Ipc.Flatbuf.Interval.t()}
          | {:List, Arrow.Ipc.Flatbuf.List.t()}
          | {:Struct_, Arrow.Ipc.Flatbuf.Struct.t()}
          | {:Union, Arrow.Ipc.Flatbuf.Union.t()}
          | {:FixedSizeBinary, Arrow.Ipc.Flatbuf.FixedSizeBinary.t()}
          | {:FixedSizeList, Arrow.Ipc.Flatbuf.FixedSizeList.t()}
          | {:Map, Arrow.Ipc.Flatbuf.Map.t()}
          | {:Duration, Arrow.Ipc.Flatbuf.Duration.t()}
          | {:LargeBinary, Arrow.Ipc.Flatbuf.LargeBinary.t()}
          | {:LargeUtf8, Arrow.Ipc.Flatbuf.LargeUtf8.t()}
          | {:LargeList, Arrow.Ipc.Flatbuf.LargeList.t()}
          | {:RunEndEncoded, Arrow.Ipc.Flatbuf.RunEndEncoded.t()}
          | {:BinaryView, Arrow.Ipc.Flatbuf.BinaryView.t()}
          | {:Utf8View, Arrow.Ipc.Flatbuf.Utf8View.t()}
          | {:ListView, Arrow.Ipc.Flatbuf.ListView.t()}
          | {:LargeListView, Arrow.Ipc.Flatbuf.LargeListView.t()}

  @doc "Integer discriminator for a variant atom (0 for :NONE)."
  @spec discriminator(atom()) :: non_neg_integer()
  def discriminator(:NONE), do: 0
  def discriminator(:Null), do: 1
  def discriminator(:Int), do: 2
  def discriminator(:FloatingPoint), do: 3
  def discriminator(:Binary), do: 4
  def discriminator(:Utf8), do: 5
  def discriminator(:Bool), do: 6
  def discriminator(:Decimal), do: 7
  def discriminator(:Date), do: 8
  def discriminator(:Time), do: 9
  def discriminator(:Timestamp), do: 10
  def discriminator(:Interval), do: 11
  def discriminator(:List), do: 12
  def discriminator(:Struct_), do: 13
  def discriminator(:Union), do: 14
  def discriminator(:FixedSizeBinary), do: 15
  def discriminator(:FixedSizeList), do: 16
  def discriminator(:Map), do: 17
  def discriminator(:Duration), do: 18
  def discriminator(:LargeBinary), do: 19
  def discriminator(:LargeUtf8), do: 20
  def discriminator(:LargeList), do: 21
  def discriminator(:RunEndEncoded), do: 22
  def discriminator(:BinaryView), do: 23
  def discriminator(:Utf8View), do: 24
  def discriminator(:ListView), do: 25
  def discriminator(:LargeListView), do: 26

  @doc "Variant atom for an integer discriminator."
  @spec variant_atom(non_neg_integer()) :: atom() | nil
  def variant_atom(0), do: :NONE
  def variant_atom(1), do: :Null
  def variant_atom(2), do: :Int
  def variant_atom(3), do: :FloatingPoint
  def variant_atom(4), do: :Binary
  def variant_atom(5), do: :Utf8
  def variant_atom(6), do: :Bool
  def variant_atom(7), do: :Decimal
  def variant_atom(8), do: :Date
  def variant_atom(9), do: :Time
  def variant_atom(10), do: :Timestamp
  def variant_atom(11), do: :Interval
  def variant_atom(12), do: :List
  def variant_atom(13), do: :Struct_
  def variant_atom(14), do: :Union
  def variant_atom(15), do: :FixedSizeBinary
  def variant_atom(16), do: :FixedSizeList
  def variant_atom(17), do: :Map
  def variant_atom(18), do: :Duration
  def variant_atom(19), do: :LargeBinary
  def variant_atom(20), do: :LargeUtf8
  def variant_atom(21), do: :LargeList
  def variant_atom(22), do: :RunEndEncoded
  def variant_atom(23), do: :BinaryView
  def variant_atom(24), do: :Utf8View
  def variant_atom(25), do: :ListView
  def variant_atom(26), do: :LargeListView
  def variant_atom(_), do: nil

  @doc """
  Decode a union value at `abs_pos`, given its discriminator. The
  `abs_pos` is the absolute target of the uoffset_t the table field
  stored — i.e. for a table variant, the table position; for a
  string variant, the start of the u32 length; for a struct variant,
  the start of the inline struct bytes.
  """
  def decode_variant(_buf, 0, _abs_pos), do: nil
  def decode_variant(buf, 1, abs_pos), do: {:Null, Arrow.Ipc.Flatbuf.Null.decode_at(buf, abs_pos)}
  def decode_variant(buf, 2, abs_pos), do: {:Int, Arrow.Ipc.Flatbuf.Int.decode_at(buf, abs_pos)}

  def decode_variant(buf, 3, abs_pos),
    do: {:FloatingPoint, Arrow.Ipc.Flatbuf.FloatingPoint.decode_at(buf, abs_pos)}

  def decode_variant(buf, 4, abs_pos),
    do: {:Binary, Arrow.Ipc.Flatbuf.Binary.decode_at(buf, abs_pos)}

  def decode_variant(buf, 5, abs_pos), do: {:Utf8, Arrow.Ipc.Flatbuf.Utf8.decode_at(buf, abs_pos)}
  def decode_variant(buf, 6, abs_pos), do: {:Bool, Arrow.Ipc.Flatbuf.Bool.decode_at(buf, abs_pos)}

  def decode_variant(buf, 7, abs_pos),
    do: {:Decimal, Arrow.Ipc.Flatbuf.Decimal.decode_at(buf, abs_pos)}

  def decode_variant(buf, 8, abs_pos), do: {:Date, Arrow.Ipc.Flatbuf.Date.decode_at(buf, abs_pos)}
  def decode_variant(buf, 9, abs_pos), do: {:Time, Arrow.Ipc.Flatbuf.Time.decode_at(buf, abs_pos)}

  def decode_variant(buf, 10, abs_pos),
    do: {:Timestamp, Arrow.Ipc.Flatbuf.Timestamp.decode_at(buf, abs_pos)}

  def decode_variant(buf, 11, abs_pos),
    do: {:Interval, Arrow.Ipc.Flatbuf.Interval.decode_at(buf, abs_pos)}

  def decode_variant(buf, 12, abs_pos),
    do: {:List, Arrow.Ipc.Flatbuf.List.decode_at(buf, abs_pos)}

  def decode_variant(buf, 13, abs_pos),
    do: {:Struct_, Arrow.Ipc.Flatbuf.Struct.decode_at(buf, abs_pos)}

  def decode_variant(buf, 14, abs_pos),
    do: {:Union, Arrow.Ipc.Flatbuf.Union.decode_at(buf, abs_pos)}

  def decode_variant(buf, 15, abs_pos),
    do: {:FixedSizeBinary, Arrow.Ipc.Flatbuf.FixedSizeBinary.decode_at(buf, abs_pos)}

  def decode_variant(buf, 16, abs_pos),
    do: {:FixedSizeList, Arrow.Ipc.Flatbuf.FixedSizeList.decode_at(buf, abs_pos)}

  def decode_variant(buf, 17, abs_pos), do: {:Map, Arrow.Ipc.Flatbuf.Map.decode_at(buf, abs_pos)}

  def decode_variant(buf, 18, abs_pos),
    do: {:Duration, Arrow.Ipc.Flatbuf.Duration.decode_at(buf, abs_pos)}

  def decode_variant(buf, 19, abs_pos),
    do: {:LargeBinary, Arrow.Ipc.Flatbuf.LargeBinary.decode_at(buf, abs_pos)}

  def decode_variant(buf, 20, abs_pos),
    do: {:LargeUtf8, Arrow.Ipc.Flatbuf.LargeUtf8.decode_at(buf, abs_pos)}

  def decode_variant(buf, 21, abs_pos),
    do: {:LargeList, Arrow.Ipc.Flatbuf.LargeList.decode_at(buf, abs_pos)}

  def decode_variant(buf, 22, abs_pos),
    do: {:RunEndEncoded, Arrow.Ipc.Flatbuf.RunEndEncoded.decode_at(buf, abs_pos)}

  def decode_variant(buf, 23, abs_pos),
    do: {:BinaryView, Arrow.Ipc.Flatbuf.BinaryView.decode_at(buf, abs_pos)}

  def decode_variant(buf, 24, abs_pos),
    do: {:Utf8View, Arrow.Ipc.Flatbuf.Utf8View.decode_at(buf, abs_pos)}

  def decode_variant(buf, 25, abs_pos),
    do: {:ListView, Arrow.Ipc.Flatbuf.ListView.decode_at(buf, abs_pos)}

  def decode_variant(buf, 26, abs_pos),
    do: {:LargeListView, Arrow.Ipc.Flatbuf.LargeListView.decode_at(buf, abs_pos)}

  def decode_variant(_buf, disc, _abs_pos), do: {:unknown_variant, disc}

  @doc """
  Build a variant value into the builder. Returns `{builder, addr}`.
  For `:NONE`, returns `{builder, nil}`.
  """
  def build_variant(b, :NONE, _value), do: {b, nil}
  def build_variant(b, :Null, value), do: Arrow.Ipc.Flatbuf.Null.build(b, value)
  def build_variant(b, :Int, value), do: Arrow.Ipc.Flatbuf.Int.build(b, value)
  def build_variant(b, :FloatingPoint, value), do: Arrow.Ipc.Flatbuf.FloatingPoint.build(b, value)
  def build_variant(b, :Binary, value), do: Arrow.Ipc.Flatbuf.Binary.build(b, value)
  def build_variant(b, :Utf8, value), do: Arrow.Ipc.Flatbuf.Utf8.build(b, value)
  def build_variant(b, :Bool, value), do: Arrow.Ipc.Flatbuf.Bool.build(b, value)
  def build_variant(b, :Decimal, value), do: Arrow.Ipc.Flatbuf.Decimal.build(b, value)
  def build_variant(b, :Date, value), do: Arrow.Ipc.Flatbuf.Date.build(b, value)
  def build_variant(b, :Time, value), do: Arrow.Ipc.Flatbuf.Time.build(b, value)
  def build_variant(b, :Timestamp, value), do: Arrow.Ipc.Flatbuf.Timestamp.build(b, value)
  def build_variant(b, :Interval, value), do: Arrow.Ipc.Flatbuf.Interval.build(b, value)
  def build_variant(b, :List, value), do: Arrow.Ipc.Flatbuf.List.build(b, value)
  def build_variant(b, :Struct_, value), do: Arrow.Ipc.Flatbuf.Struct.build(b, value)
  def build_variant(b, :Union, value), do: Arrow.Ipc.Flatbuf.Union.build(b, value)

  def build_variant(b, :FixedSizeBinary, value),
    do: Arrow.Ipc.Flatbuf.FixedSizeBinary.build(b, value)

  def build_variant(b, :FixedSizeList, value), do: Arrow.Ipc.Flatbuf.FixedSizeList.build(b, value)
  def build_variant(b, :Map, value), do: Arrow.Ipc.Flatbuf.Map.build(b, value)
  def build_variant(b, :Duration, value), do: Arrow.Ipc.Flatbuf.Duration.build(b, value)
  def build_variant(b, :LargeBinary, value), do: Arrow.Ipc.Flatbuf.LargeBinary.build(b, value)
  def build_variant(b, :LargeUtf8, value), do: Arrow.Ipc.Flatbuf.LargeUtf8.build(b, value)
  def build_variant(b, :LargeList, value), do: Arrow.Ipc.Flatbuf.LargeList.build(b, value)
  def build_variant(b, :RunEndEncoded, value), do: Arrow.Ipc.Flatbuf.RunEndEncoded.build(b, value)
  def build_variant(b, :BinaryView, value), do: Arrow.Ipc.Flatbuf.BinaryView.build(b, value)
  def build_variant(b, :Utf8View, value), do: Arrow.Ipc.Flatbuf.Utf8View.build(b, value)
  def build_variant(b, :ListView, value), do: Arrow.Ipc.Flatbuf.ListView.build(b, value)
  def build_variant(b, :LargeListView, value), do: Arrow.Ipc.Flatbuf.LargeListView.build(b, value)

  # JSON helpers — used by table codegen for the paired `_type` and
  # value keys flatc emits.

  @doc false
  # flatc emits the union `_type` key as `"NONE"` (not omitted) when
  # the discriminator is 0, so match that to keep JSON comparisons
  # aligned. The value side stays nil and gets dropped by the
  # caller's `Map.reject`.
  def __to_json_type__(nil), do: "NONE"
  def __to_json_type__({variant, _value}), do: Atom.to_string(variant)

  @doc false
  def __to_json_value__(nil), do: nil
  def __to_json_value__({:Null, value}), do: Arrow.Ipc.Flatbuf.Null.__to_json_map__(value)
  def __to_json_value__({:Int, value}), do: Arrow.Ipc.Flatbuf.Int.__to_json_map__(value)

  def __to_json_value__({:FloatingPoint, value}),
    do: Arrow.Ipc.Flatbuf.FloatingPoint.__to_json_map__(value)

  def __to_json_value__({:Binary, value}), do: Arrow.Ipc.Flatbuf.Binary.__to_json_map__(value)
  def __to_json_value__({:Utf8, value}), do: Arrow.Ipc.Flatbuf.Utf8.__to_json_map__(value)
  def __to_json_value__({:Bool, value}), do: Arrow.Ipc.Flatbuf.Bool.__to_json_map__(value)
  def __to_json_value__({:Decimal, value}), do: Arrow.Ipc.Flatbuf.Decimal.__to_json_map__(value)
  def __to_json_value__({:Date, value}), do: Arrow.Ipc.Flatbuf.Date.__to_json_map__(value)
  def __to_json_value__({:Time, value}), do: Arrow.Ipc.Flatbuf.Time.__to_json_map__(value)

  def __to_json_value__({:Timestamp, value}),
    do: Arrow.Ipc.Flatbuf.Timestamp.__to_json_map__(value)

  def __to_json_value__({:Interval, value}), do: Arrow.Ipc.Flatbuf.Interval.__to_json_map__(value)
  def __to_json_value__({:List, value}), do: Arrow.Ipc.Flatbuf.List.__to_json_map__(value)
  def __to_json_value__({:Struct_, value}), do: Arrow.Ipc.Flatbuf.Struct.__to_json_map__(value)
  def __to_json_value__({:Union, value}), do: Arrow.Ipc.Flatbuf.Union.__to_json_map__(value)

  def __to_json_value__({:FixedSizeBinary, value}),
    do: Arrow.Ipc.Flatbuf.FixedSizeBinary.__to_json_map__(value)

  def __to_json_value__({:FixedSizeList, value}),
    do: Arrow.Ipc.Flatbuf.FixedSizeList.__to_json_map__(value)

  def __to_json_value__({:Map, value}), do: Arrow.Ipc.Flatbuf.Map.__to_json_map__(value)
  def __to_json_value__({:Duration, value}), do: Arrow.Ipc.Flatbuf.Duration.__to_json_map__(value)

  def __to_json_value__({:LargeBinary, value}),
    do: Arrow.Ipc.Flatbuf.LargeBinary.__to_json_map__(value)

  def __to_json_value__({:LargeUtf8, value}),
    do: Arrow.Ipc.Flatbuf.LargeUtf8.__to_json_map__(value)

  def __to_json_value__({:LargeList, value}),
    do: Arrow.Ipc.Flatbuf.LargeList.__to_json_map__(value)

  def __to_json_value__({:RunEndEncoded, value}),
    do: Arrow.Ipc.Flatbuf.RunEndEncoded.__to_json_map__(value)

  def __to_json_value__({:BinaryView, value}),
    do: Arrow.Ipc.Flatbuf.BinaryView.__to_json_map__(value)

  def __to_json_value__({:Utf8View, value}), do: Arrow.Ipc.Flatbuf.Utf8View.__to_json_map__(value)
  def __to_json_value__({:ListView, value}), do: Arrow.Ipc.Flatbuf.ListView.__to_json_map__(value)

  def __to_json_value__({:LargeListView, value}),
    do: Arrow.Ipc.Flatbuf.LargeListView.__to_json_map__(value)

  @doc false
  def __from_json__(nil, _value), do: nil
  def __from_json__("NONE", _value), do: nil
  def __from_json__("Null", value), do: {:Null, Arrow.Ipc.Flatbuf.Null.__from_json_map__(value)}
  def __from_json__("Int", value), do: {:Int, Arrow.Ipc.Flatbuf.Int.__from_json_map__(value)}

  def __from_json__("FloatingPoint", value),
    do: {:FloatingPoint, Arrow.Ipc.Flatbuf.FloatingPoint.__from_json_map__(value)}

  def __from_json__("Binary", value),
    do: {:Binary, Arrow.Ipc.Flatbuf.Binary.__from_json_map__(value)}

  def __from_json__("Utf8", value), do: {:Utf8, Arrow.Ipc.Flatbuf.Utf8.__from_json_map__(value)}
  def __from_json__("Bool", value), do: {:Bool, Arrow.Ipc.Flatbuf.Bool.__from_json_map__(value)}

  def __from_json__("Decimal", value),
    do: {:Decimal, Arrow.Ipc.Flatbuf.Decimal.__from_json_map__(value)}

  def __from_json__("Date", value), do: {:Date, Arrow.Ipc.Flatbuf.Date.__from_json_map__(value)}
  def __from_json__("Time", value), do: {:Time, Arrow.Ipc.Flatbuf.Time.__from_json_map__(value)}

  def __from_json__("Timestamp", value),
    do: {:Timestamp, Arrow.Ipc.Flatbuf.Timestamp.__from_json_map__(value)}

  def __from_json__("Interval", value),
    do: {:Interval, Arrow.Ipc.Flatbuf.Interval.__from_json_map__(value)}

  def __from_json__("List", value), do: {:List, Arrow.Ipc.Flatbuf.List.__from_json_map__(value)}

  def __from_json__("Struct_", value),
    do: {:Struct_, Arrow.Ipc.Flatbuf.Struct.__from_json_map__(value)}

  def __from_json__("Union", value),
    do: {:Union, Arrow.Ipc.Flatbuf.Union.__from_json_map__(value)}

  def __from_json__("FixedSizeBinary", value),
    do: {:FixedSizeBinary, Arrow.Ipc.Flatbuf.FixedSizeBinary.__from_json_map__(value)}

  def __from_json__("FixedSizeList", value),
    do: {:FixedSizeList, Arrow.Ipc.Flatbuf.FixedSizeList.__from_json_map__(value)}

  def __from_json__("Map", value), do: {:Map, Arrow.Ipc.Flatbuf.Map.__from_json_map__(value)}

  def __from_json__("Duration", value),
    do: {:Duration, Arrow.Ipc.Flatbuf.Duration.__from_json_map__(value)}

  def __from_json__("LargeBinary", value),
    do: {:LargeBinary, Arrow.Ipc.Flatbuf.LargeBinary.__from_json_map__(value)}

  def __from_json__("LargeUtf8", value),
    do: {:LargeUtf8, Arrow.Ipc.Flatbuf.LargeUtf8.__from_json_map__(value)}

  def __from_json__("LargeList", value),
    do: {:LargeList, Arrow.Ipc.Flatbuf.LargeList.__from_json_map__(value)}

  def __from_json__("RunEndEncoded", value),
    do: {:RunEndEncoded, Arrow.Ipc.Flatbuf.RunEndEncoded.__from_json_map__(value)}

  def __from_json__("BinaryView", value),
    do: {:BinaryView, Arrow.Ipc.Flatbuf.BinaryView.__from_json_map__(value)}

  def __from_json__("Utf8View", value),
    do: {:Utf8View, Arrow.Ipc.Flatbuf.Utf8View.__from_json_map__(value)}

  def __from_json__("ListView", value),
    do: {:ListView, Arrow.Ipc.Flatbuf.ListView.__from_json_map__(value)}

  def __from_json__("LargeListView", value),
    do: {:LargeListView, Arrow.Ipc.Flatbuf.LargeListView.__from_json_map__(value)}

  @doc false
  def __verify_variant__(_buf, 0, _abs_pos, _depth), do: :ok

  def __verify_variant__(buf, 1, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Null.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 2, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Int.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 3, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.FloatingPoint.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 4, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Binary.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 5, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Utf8.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 6, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Bool.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 7, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Decimal.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 8, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Date.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 9, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Time.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 10, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Timestamp.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 11, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Interval.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 12, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.List.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 13, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Struct.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 14, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Union.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 15, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.FixedSizeBinary.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 16, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.FixedSizeList.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 17, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Map.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 18, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Duration.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 19, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.LargeBinary.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 20, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.LargeUtf8.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 21, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.LargeList.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 22, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.RunEndEncoded.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 23, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.BinaryView.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 24, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.Utf8View.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 25, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.ListView.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(buf, 26, abs_pos, depth),
    do: Arrow.Ipc.Flatbuf.LargeListView.__verify_at__(buf, abs_pos, depth)

  def __verify_variant__(_buf, disc, _abs_pos, _depth),
    do: {:error, {:unknown_union_variant, disc}}
end
