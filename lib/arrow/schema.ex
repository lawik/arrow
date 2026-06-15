# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.Schema do
  @moduledoc """
  Ordered list of `Arrow.Field` plus an optional schema-level metadata map.

  Arrow schemas describe the columns of a record batch (or stream of batches).
  """

  defstruct fields: [], metadata: %{}

  @type t :: %__MODULE__{
          fields: [Arrow.Field.t()],
          metadata: %{optional(String.t()) => String.t()}
        }
end
