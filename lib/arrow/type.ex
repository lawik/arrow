defmodule Arrow.Type.Null do
  @moduledoc "Logical Null type. Carries no data — only a length."
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.Bool do
  @moduledoc "Logical boolean type. Stored as a packed bitmap."
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.Int do
  @moduledoc """
  Signed or unsigned integer of a given bit width.

  The Arrow spec permits bit widths 8, 16, 32, 64 (Tier 1).
  """
  defstruct [:bit_width, :signed]

  @type bit_width :: 8 | 16 | 32 | 64
  @type t :: %__MODULE__{bit_width: bit_width(), signed: boolean()}
end

defmodule Arrow.Type.FloatingPoint do
  @moduledoc "IEEE-754 floating point. Tier 1: `:single`, `:double`."
  defstruct [:precision]

  @type precision :: :half | :single | :double
  @type t :: %__MODULE__{precision: precision()}
end

defmodule Arrow.Type.Utf8 do
  @moduledoc "Variable-length UTF-8 string column."
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.Binary do
  @moduledoc "Variable-length opaque byte column."
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.Date do
  @moduledoc """
  Date column.

  - `:day` — 32-bit days since the UNIX epoch (`Date32`).
  - `:millisecond` — 64-bit milliseconds since the UNIX epoch (`Date64`).
  """
  defstruct [:unit]

  @type unit :: :day | :millisecond
  @type t :: %__MODULE__{unit: unit()}
end

defmodule Arrow.Type.Timestamp do
  @moduledoc """
  64-bit timestamp at a fixed time unit, optionally annotated with a timezone.

  `timezone: nil` means "naive" (no timezone), per Arrow's distinction
  between naive and zoned timestamps.
  """
  defstruct [:unit, :timezone]

  @type unit :: :second | :millisecond | :microsecond | :nanosecond
  @type t :: %__MODULE__{unit: unit(), timezone: String.t() | nil}
end

defmodule Arrow.Type.List do
  @moduledoc """
  Variable-length list of an inner type. The inner type is described by the
  single child field of the enclosing `Arrow.Field`.
  """
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.Struct do
  @moduledoc """
  Tuple-of-columns. Child fields are the struct's members, in declaration order,
  and live on the enclosing `Arrow.Field`.
  """
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.Time do
  @moduledoc """
  Time-of-day column. The Arrow FlatBuffers table parameterises both the bit
  width and the unit:

  - `bit_width: 32` with `:second` or `:millisecond` (`Time32`).
  - `bit_width: 64` with `:microsecond` or `:nanosecond` (`Time64`).
  """
  defstruct [:unit, :bit_width]

  @type unit :: :second | :millisecond | :microsecond | :nanosecond
  @type bit_width :: 32 | 64
  @type t :: %__MODULE__{unit: unit(), bit_width: bit_width()}
end

defmodule Arrow.Type.Duration do
  @moduledoc "64-bit elapsed-time column in a fixed unit."
  defstruct [:unit]

  @type unit :: :second | :millisecond | :microsecond | :nanosecond
  @type t :: %__MODULE__{unit: unit()}
end

defmodule Arrow.Type.FixedSizeBinary do
  @moduledoc "Fixed-width opaque-bytes column. Every slot is `byte_width` bytes."
  defstruct [:byte_width]

  @type t :: %__MODULE__{byte_width: pos_integer()}
end

defmodule Arrow.Type.FixedSizeList do
  @moduledoc """
  Fixed-size list of an inner type. Every slot is exactly `list_size` items;
  there is no offsets buffer. The inner type is the single child field of the
  enclosing `Arrow.Field`.
  """
  defstruct [:list_size]

  @type t :: %__MODULE__{list_size: pos_integer()}
end

defmodule Arrow.Type.Decimal do
  @moduledoc """
  Fixed-point decimal column. Stored as a little-endian two's-complement
  integer of `bit_width` bits, scaled by `10^-scale`.

  Tier 2 covers `bit_width: 128`; `256` is Tier 3.
  """
  defstruct [:bit_width, :precision, :scale]

  @type bit_width :: 128 | 256
  @type t :: %__MODULE__{
          bit_width: bit_width(),
          precision: pos_integer(),
          scale: integer()
        }
end

defmodule Arrow.Type.Map do
  @moduledoc """
  Map column. Structurally a `List<Struct<key, value>>` with a single child
  field named "entries"; the entries struct's two children are the key and
  value fields.
  """
  defstruct keys_sorted: false

  @type t :: %__MODULE__{keys_sorted: boolean()}
end

defmodule Arrow.Type.LargeUtf8 do
  @moduledoc "Variable-length UTF-8 string column with 64-bit offsets."
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.LargeBinary do
  @moduledoc "Variable-length opaque byte column with 64-bit offsets."
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.LargeList do
  @moduledoc """
  Variable-length list with 64-bit offsets. Otherwise identical to
  `Arrow.Type.List`.
  """
  defstruct []
  @type t :: %__MODULE__{}
end

defmodule Arrow.Type.Interval do
  @moduledoc """
  Interval column. Three concrete physical layouts:

  - `:year_month` — int32 months
  - `:day_time` — pair of int32s {days, milliseconds}, 8 bytes per slot
  - `:month_day_nano` — {int32 months, int32 days, int64 nanoseconds},
    16 bytes per slot
  """
  defstruct [:unit]

  @type unit :: :year_month | :day_time | :month_day_nano
  @type t :: %__MODULE__{unit: unit()}
end

defmodule Arrow.Type.DictionaryEncoding do
  @moduledoc """
  Dictionary-encoding annotation on a `Arrow.Field`.

  `id` is the dictionary's identifier within the IPC session — multiple
  fields can share a single dictionary by referring to the same `id`.
  `index_type` is the integer type used to index into the dictionary
  from a record batch column. `is_ordered` indicates the dictionary
  values are sorted in ascending order; some consumers rely on that.

  This is *not* an `Arrow.Type` variant. The enclosing field's `type`
  continues to describe the dictionary's *value* type. The
  `DictionaryEncoding` lives on `Arrow.Field.dictionary`.
  """
  @enforce_keys [:id, :index_type]
  defstruct [:id, :index_type, is_ordered: false]

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          index_type: Arrow.Type.Int.t(),
          is_ordered: boolean()
        }
end

defmodule Arrow.Type do
  @moduledoc """
  Arrow logical types. Each type is a distinct struct under `Arrow.Type.*`.

  Types parameterized by FlatBuffers tables (`Int`, `FloatingPoint`, `Date`,
  `Timestamp`, ...) carry their parameters as fields. Children of nested types
  (`List`, `Struct`) live on the enclosing `Arrow.Field`, mirroring the Arrow
  schema layout.
  """

  alias Arrow.Type.{
    Binary,
    Bool,
    Date,
    Decimal,
    Duration,
    FixedSizeBinary,
    FixedSizeList,
    FloatingPoint,
    Int,
    List,
    Interval,
    LargeBinary,
    LargeList,
    LargeUtf8,
    Map,
    Null,
    Struct,
    Time,
    Timestamp,
    Utf8
  }

  @type t ::
          %Null{}
          | %Bool{}
          | %Int{}
          | %FloatingPoint{}
          | %Utf8{}
          | %Binary{}
          | %Date{}
          | %Timestamp{}
          | %List{}
          | %Struct{}
          | %Time{}
          | %Duration{}
          | %FixedSizeBinary{}
          | %FixedSizeList{}
          | %Decimal{}
          | %Map{}
          | %Interval{}
          | %LargeUtf8{}
          | %LargeBinary{}
          | %LargeList{}

  @doc "Returns the in-memory width in bits of a primitive numeric type."
  @spec bit_width(t()) :: pos_integer()
  def bit_width(%Int{bit_width: w}), do: w
  def bit_width(%FloatingPoint{precision: :half}), do: 16
  def bit_width(%FloatingPoint{precision: :single}), do: 32
  def bit_width(%FloatingPoint{precision: :double}), do: 64
  def bit_width(%Date{unit: :day}), do: 32
  def bit_width(%Date{unit: :millisecond}), do: 64
  def bit_width(%Timestamp{}), do: 64
  def bit_width(%Bool{}), do: 1
  def bit_width(%Time{bit_width: w}), do: w
  def bit_width(%Duration{}), do: 64
  def bit_width(%Decimal{bit_width: w}), do: w
end
