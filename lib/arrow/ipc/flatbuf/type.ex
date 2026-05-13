defmodule Arrow.Ipc.Flatbuf.Type do
  @moduledoc "Generated from FlatBuffers union Arrow.Ipc.Flatbuf.Type. Do not edit."

  alias Arrow.Ipc.Flatbuf.Wire, as: Wire

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
end
