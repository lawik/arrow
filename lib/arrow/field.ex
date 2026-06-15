# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
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

  @doc """
  Returns the field with its `dictionary` annotation stripped — i.e. a
  field that describes the *value* type only. Used when decoding the
  contents of a `DictionaryBatch`, where the buffers carry the dictionary
  values rather than indices.
  """
  @spec value_field(t()) :: t()
  def value_field(%__MODULE__{} = f), do: %__MODULE__{f | dictionary: nil}

  @doc """
  Walks the field tree under `schema_or_fields` and returns the first
  field whose dictionary annotation has the given id, or `nil`.
  """
  @spec find_by_dictionary_id(Arrow.Schema.t() | [t()], non_neg_integer()) :: t() | nil
  def find_by_dictionary_id(%Arrow.Schema{fields: fields}, target),
    do: find_by_dictionary_id(fields, target)

  def find_by_dictionary_id(fields, target) when is_list(fields) do
    Enum.find_value(fields, fn f -> walk_for_dict(f, target) end)
  end

  defp walk_for_dict(%__MODULE__{dictionary: %{id: id}} = f, target) when id == target, do: f

  defp walk_for_dict(%__MODULE__{children: children}, target),
    do: find_by_dictionary_id(children, target)
end
