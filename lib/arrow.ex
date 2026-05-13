defmodule Arrow do
  @moduledoc """
  Pure-Elixir implementation of the [Apache Arrow](https://arrow.apache.org/)
  columnar format.

  This top-level module is intentionally thin. The library's surface area lives
  under:

  - `Arrow.Schema`, `Arrow.Field`, `Arrow.Type.*` — schema description.
  - `Arrow.Array.*` — per-type columnar arrays.
  - `Arrow.RecordBatch` — schema + columns batch.
  - `Arrow.Buffer` — encoder/decoder between in-memory arrays and the on-wire
    buffer layout.
  - `Arrow.Json` — Arrow integration test JSON form, used for
    cross-implementation conformance.
  """
end
