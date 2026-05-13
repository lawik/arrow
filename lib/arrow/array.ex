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

defmodule Arrow.Array do
  @moduledoc """
  Per-type column structs. Each module under `Arrow.Array.*` represents one
  concrete Arrow array.

  ## Shape

  Primitive arrays carry a validity bitmap and a value buffer:

      %Arrow.Array.Int64{length: 3, null_count: 1,
                         validity: <<0b101::3>>,
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
    Float32,
    Float64,
    Int16,
    Int32,
    Int64,
    Int8,
    List,
    Null,
    Struct,
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

  @doc "The number of slots in the array (`length`)."
  @spec length(t()) :: non_neg_integer()
  def length(%{length: n}), do: n

  @doc "The number of null slots in the array (`null_count`)."
  @spec null_count(t()) :: non_neg_integer()
  def null_count(%Null{length: n}), do: n
  def null_count(%{null_count: n}), do: n
end
