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
    FloatingPoint,
    Int,
    List,
    Null,
    Struct,
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
end
