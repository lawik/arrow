defmodule Arrow.Field do
  @moduledoc """
  A named column within a schema. Holds the logical type, nullability, an
  optional per-field metadata map, the child fields used by nested types
  (`List`, `Struct`), and an optional `Arrow.Type.DictionaryEncoding` when
  the field is dictionary-encoded.

  Dictionary encoding in Arrow is a *property of the field*, not a type:
  the `type` continues to describe what the dictionary stores (e.g.
  `Utf8`), while `dictionary.index_type` describes the integer type used
  in record batches to reference dictionary entries.
  """

  @enforce_keys [:name, :type]
  defstruct name: nil,
            type: nil,
            nullable: true,
            children: [],
            metadata: %{},
            dictionary: nil

  @type metadata :: %{optional(String.t()) => String.t()}

  @type t :: %__MODULE__{
          name: String.t(),
          type: Arrow.Type.t(),
          nullable: boolean(),
          children: [t()],
          metadata: metadata(),
          dictionary: Arrow.Type.DictionaryEncoding.t() | nil
        }
end
