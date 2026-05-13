defmodule Arrow.Field do
  @moduledoc """
  A named column within a schema. Holds the logical type, nullability, an
  optional per-field metadata map, and the child fields used by nested types
  (`List`, `Struct`).
  """

  @enforce_keys [:name, :type]
  defstruct name: nil,
            type: nil,
            nullable: true,
            children: [],
            metadata: %{}

  @type metadata :: %{optional(String.t()) => String.t()}

  @type t :: %__MODULE__{
          name: String.t(),
          type: Arrow.Type.t(),
          nullable: boolean(),
          children: [t()],
          metadata: metadata()
        }
end
