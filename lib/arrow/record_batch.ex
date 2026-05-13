defmodule Arrow.RecordBatch do
  @moduledoc """
  A batch of columnar data: a schema, a row count, and one column per field.

  The column at position `i` corresponds to the field at position `i` in the
  schema, and every column reports the same `length`.
  """

  @enforce_keys [:schema, :length, :columns]
  defstruct [:schema, :length, :columns]

  @type t :: %__MODULE__{
          schema: Arrow.Schema.t(),
          length: non_neg_integer(),
          columns: [Arrow.Array.t()]
        }
end
