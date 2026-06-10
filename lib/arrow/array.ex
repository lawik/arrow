defmodule Arrow.Array.Null do
  @moduledoc "All-null column. Carries only a length."
  @enforce_keys [:length]
  defstruct [:length]
  @type t :: %__MODULE__{length: non_neg_integer()}
end

defmodule Arrow.Array.Bool do
  @moduledoc "Boolean column. Values are a packed LSB-first bitmap."
  @enforce_keys [:length, :null_count, :values]
  defstruct length: 0, null_count: 0, validity: nil, values: <<>>

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          values: binary()
        }
end

for mod <- [
      Arrow.Array.Int8,
      Arrow.Array.Int16,
      Arrow.Array.Int32,
      Arrow.Array.Int64,
      Arrow.Array.UInt8,
      Arrow.Array.UInt16,
      Arrow.Array.UInt32,
      Arrow.Array.UInt64,
      Arrow.Array.Float32,
      Arrow.Array.Float64,
      Arrow.Array.Date32,
      Arrow.Array.Date64
    ] do
  defmodule mod do
    @moduledoc """
    Fixed-width primitive column. `values` is a little-endian packed buffer of
    one element per slot, regardless of `validity`.
    """
    @enforce_keys [:length, :null_count, :values]
    defstruct length: 0, null_count: 0, validity: nil, values: <<>>

    @type t :: %__MODULE__{
            length: non_neg_integer(),
            null_count: non_neg_integer(),
            validity: binary() | nil,
            values: binary()
          }
  end
end

defmodule Arrow.Array.Timestamp do
  @moduledoc """
  64-bit timestamp column. Values are little-endian signed `int64`s in the
  declared `unit`. `timezone: nil` means a naive (unzoned) timestamp.
  """
  @enforce_keys [:unit, :length, :null_count, :values]
  defstruct unit: nil, timezone: nil, length: 0, null_count: 0, validity: nil, values: <<>>

  @type t :: %__MODULE__{
          unit: Arrow.Type.Timestamp.unit(),
          timezone: String.t() | nil,
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          values: binary()
        }
end

defmodule Arrow.Array.Utf8 do
  @moduledoc """
  Variable-length UTF-8 column. `offsets` is `length + 1` little-endian
  `int32`s; `values` is the concatenation of every slot's UTF-8 bytes.
  """
  @enforce_keys [:length, :null_count, :offsets, :values]
  defstruct length: 0, null_count: 0, validity: nil, offsets: <<>>, values: <<>>

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          offsets: binary(),
          values: binary()
        }
end

defmodule Arrow.Array.Binary do
  @moduledoc """
  Variable-length opaque-bytes column. Same layout as `Arrow.Array.Utf8` but
  the value bytes are not constrained to be valid UTF-8.
  """
  @enforce_keys [:length, :null_count, :offsets, :values]
  defstruct length: 0, null_count: 0, validity: nil, offsets: <<>>, values: <<>>

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          offsets: binary(),
          values: binary()
        }
end

defmodule Arrow.Array.List do
  @moduledoc """
  Variable-length list column. `offsets` is `length + 1` little-endian `int32`s
  giving the [start, end) index of each slot's items in `values` (the child
  array).
  """
  @enforce_keys [:length, :null_count, :offsets, :values]
  defstruct length: 0, null_count: 0, validity: nil, offsets: <<>>, values: nil

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          offsets: binary(),
          values: Arrow.Array.t()
        }
end

defmodule Arrow.Array.Struct do
  @moduledoc """
  Struct column. `children` is one inner array per struct member, in the same
  order as the parent field's `children`. Every child array's `length` matches
  the struct's `length`.
  """
  @enforce_keys [:length, :null_count, :children]
  defstruct length: 0, null_count: 0, validity: nil, children: []

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          children: [Arrow.Array.t()]
        }
end

defmodule Arrow.Array.Time32 do
  @moduledoc """
  32-bit time-of-day column. Values are little-endian signed `int32`s in the
  declared `unit` (`:second` or `:millisecond`).
  """
  @enforce_keys [:unit, :length, :null_count, :values]
  defstruct unit: nil, length: 0, null_count: 0, validity: nil, values: <<>>

  @type t :: %__MODULE__{
          unit: :second | :millisecond,
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          values: binary()
        }
end

defmodule Arrow.Array.Time64 do
  @moduledoc """
  64-bit time-of-day column. Values are little-endian signed `int64`s in the
  declared `unit` (`:microsecond` or `:nanosecond`).
  """
  @enforce_keys [:unit, :length, :null_count, :values]
  defstruct unit: nil, length: 0, null_count: 0, validity: nil, values: <<>>

  @type t :: %__MODULE__{
          unit: :microsecond | :nanosecond,
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          values: binary()
        }
end

defmodule Arrow.Array.Duration do
  @moduledoc """
  64-bit elapsed-time column. Values are little-endian signed `int64`s in the
  declared `unit`.
  """
  @enforce_keys [:unit, :length, :null_count, :values]
  defstruct unit: nil, length: 0, null_count: 0, validity: nil, values: <<>>

  @type t :: %__MODULE__{
          unit: Arrow.Type.Duration.unit(),
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          values: binary()
        }
end

defmodule Arrow.Array.FixedSizeBinary do
  @moduledoc """
  Fixed-width binary column. `values` is exactly `length * byte_width` bytes
  (no offsets).
  """
  @enforce_keys [:byte_width, :length, :null_count, :values]
  defstruct byte_width: 0, length: 0, null_count: 0, validity: nil, values: <<>>

  @type t :: %__MODULE__{
          byte_width: pos_integer(),
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          values: binary()
        }
end

defmodule Arrow.Array.FixedSizeList do
  @moduledoc """
  Fixed-size list column. The single child array `values` holds exactly
  `length * list_size` items; there are no offsets.
  """
  @enforce_keys [:list_size, :length, :null_count, :values]
  defstruct list_size: 0, length: 0, null_count: 0, validity: nil, values: nil

  @type t :: %__MODULE__{
          list_size: pos_integer(),
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          values: Arrow.Array.t()
        }
end

for {mod, _bytes} <- [
      {Arrow.Array.Decimal32, 4},
      {Arrow.Array.Decimal64, 8},
      {Arrow.Array.Decimal128, 16},
      {Arrow.Array.Decimal256, 32}
    ] do
  defmodule mod do
    @moduledoc """
    Fixed-point decimal column. Values are little-endian two's-complement
    integers of the type's bit width (4 / 8 / 16 / 32 bytes per slot).
    `precision` and `scale` come from the column's type; we carry them on
    the array so it's self-describing.
    """
    @enforce_keys [:precision, :scale, :length, :null_count, :values]
    defstruct precision: 0,
              scale: 0,
              length: 0,
              null_count: 0,
              validity: nil,
              values: <<>>

    @type t :: %__MODULE__{
            precision: pos_integer(),
            scale: integer(),
            length: non_neg_integer(),
            null_count: non_neg_integer(),
            validity: binary() | nil,
            values: binary()
          }
  end
end

defmodule Arrow.Array.Map do
  @moduledoc """
  Map column. Layout mirrors `Arrow.Array.List`: a validity bitmap and int32
  offsets buffer with a child `values` array. The child is expected to be an
  `Arrow.Array.Struct` whose two members are the key and the value.
  """
  @enforce_keys [:length, :null_count, :offsets, :values]
  defstruct keys_sorted: false,
            length: 0,
            null_count: 0,
            validity: nil,
            offsets: <<>>,
            values: nil

  @type t :: %__MODULE__{
          keys_sorted: boolean(),
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          offsets: binary(),
          values: Arrow.Array.Struct.t()
        }
end

defmodule Arrow.Array.LargeUtf8 do
  @moduledoc """
  Variable-length UTF-8 column with 64-bit offsets. Same shape as
  `Arrow.Array.Utf8` but `offsets` is `length + 1` little-endian `int64`s.
  """
  @enforce_keys [:length, :null_count, :offsets, :values]
  defstruct length: 0, null_count: 0, validity: nil, offsets: <<>>, values: <<>>

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          offsets: binary(),
          values: binary()
        }
end

defmodule Arrow.Array.LargeBinary do
  @moduledoc "Variable-length opaque-bytes column with 64-bit offsets."
  @enforce_keys [:length, :null_count, :offsets, :values]
  defstruct length: 0, null_count: 0, validity: nil, offsets: <<>>, values: <<>>

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          offsets: binary(),
          values: binary()
        }
end

defmodule Arrow.Array.LargeList do
  @moduledoc """
  Variable-length list with 64-bit offsets. Same shape as
  `Arrow.Array.List` but `offsets` is `length + 1` little-endian `int64`s.
  """
  @enforce_keys [:length, :null_count, :offsets, :values]
  defstruct length: 0, null_count: 0, validity: nil, offsets: <<>>, values: nil

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          null_count: non_neg_integer(),
          validity: binary() | nil,
          offsets: binary(),
          values: Arrow.Array.t()
        }
end

for mod <- [
      Arrow.Array.IntervalYearMonth,
      Arrow.Array.IntervalDayTime,
      Arrow.Array.IntervalMonthDayNano
    ] do
  defmodule mod do
    @moduledoc """
    Interval column. The physical layout depends on the variant:

    - `IntervalYearMonth` — `values` is little-endian int32 months,
      4 bytes per slot.
    - `IntervalDayTime` — `values` is little-endian {int32 days,
      int32 milliseconds}, 8 bytes per slot.
    - `IntervalMonthDayNano` — `values` is little-endian {int32
      months, int32 days, int64 nanoseconds}, 16 bytes per slot.
    """
    @enforce_keys [:length, :null_count, :values]
    defstruct length: 0, null_count: 0, validity: nil, values: <<>>

    @type t :: %__MODULE__{
            length: non_neg_integer(),
            null_count: non_neg_integer(),
            validity: binary() | nil,
            values: binary()
          }
  end
end

defmodule Arrow.Array.Dictionary do
  @moduledoc """
  Dictionary-encoded column. The buffer is just the *indices* (a
  primitive integer array referencing entries in a dictionary stored
  separately, identified by `dictionary_id`).

  The dictionary itself is *not* held on the array. It's transmitted in
  the IPC stream as a `DictionaryBatch` message and held in the
  decoder's session-level registry — `Arrow.Logical.batches_equal?/3`
  and similar comparators that need to resolve the underlying values
  take the registry as an additional argument.
  """
  @enforce_keys [:dictionary_id, :indices]
  defstruct [:dictionary_id, :indices]

  @type t :: %__MODULE__{
          dictionary_id: non_neg_integer(),
          indices: Arrow.Array.t()
        }
end

defmodule Arrow.Array do
  @moduledoc """
  Per-type column structs. Each module under `Arrow.Array.*` represents one
  concrete Arrow array.

  ## Shape

  Primitive arrays carry a validity bitmap and a value buffer:

      %Arrow.Array.Int64{length: 3, null_count: 1,
                         # LSB-first: slots 0 and 2 valid, slot 1 null
                         validity: <<0b00000101>>,
                         values:   <<1::little-signed-64,
                                     0::little-signed-64,
                                     3::little-signed-64>>}

  Variable-binary arrays (`Utf8`, `Binary`) add an offsets buffer of `length + 1`
  little-endian `int32`s; entry `i` of the value buffer is the byte range
  `offsets[i]..offsets[i+1]`.

  `List` arrays mirror that layout with a child array in place of the value
  bytes. `Struct` arrays carry one child array per struct member and no value
  buffer.

  The validity bitmap is laid out as Arrow specifies: bit `i` of byte
  `floor(i/8)`, with bit 0 being the least-significant bit. A bit value of `1`
  means the slot is valid; `0` means null. The bitmap may be omitted (set to
  `nil`) when `null_count = 0`.
  """

  alias Arrow.Array.{
    Binary,
    Bool,
    Date32,
    Date64,
    Decimal128,
    Decimal256,
    Decimal32,
    Decimal64,
    Dictionary,
    Duration,
    FixedSizeBinary,
    FixedSizeList,
    Float32,
    Float64,
    Int16,
    Int32,
    Int64,
    Int8,
    IntervalDayTime,
    IntervalMonthDayNano,
    IntervalYearMonth,
    LargeBinary,
    LargeList,
    LargeUtf8,
    List,
    Map,
    Null,
    Struct,
    Time32,
    Time64,
    Timestamp,
    UInt16,
    UInt32,
    UInt64,
    UInt8,
    Utf8
  }

  @type t ::
          %Null{}
          | %Bool{}
          | %Int8{}
          | %Int16{}
          | %Int32{}
          | %Int64{}
          | %UInt8{}
          | %UInt16{}
          | %UInt32{}
          | %UInt64{}
          | %Float32{}
          | %Float64{}
          | %Utf8{}
          | %Binary{}
          | %Date32{}
          | %Date64{}
          | %Timestamp{}
          | %List{}
          | %Struct{}
          | %Time32{}
          | %Time64{}
          | %Duration{}
          | %FixedSizeBinary{}
          | %FixedSizeList{}
          | %Decimal32{}
          | %Decimal64{}
          | %Decimal128{}
          | %Decimal256{}
          | %Map{}
          | %Dictionary{}
          | %IntervalYearMonth{}
          | %IntervalDayTime{}
          | %IntervalMonthDayNano{}
          | %LargeUtf8{}
          | %LargeBinary{}
          | %LargeList{}

  @doc "The number of slots in the array (`length`)."
  @spec length(t()) :: non_neg_integer()
  def length(%{length: n}), do: n

  @doc "The number of null slots in the array (`null_count`)."
  @spec null_count(t()) :: non_neg_integer()
  def null_count(%Null{length: n}), do: n
  def null_count(%{null_count: n}), do: n
end
