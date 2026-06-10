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

  ## Example

  Encode a record batch to the IPC streaming format and decode it back:

      iex> schema = %Arrow.Schema{
      ...>   fields: [%Arrow.Field{name: "id", type: %Arrow.Type.Int{bit_width: 32, signed: true}}]
      ...> }
      iex> batch = %Arrow.RecordBatch{
      ...>   schema: schema,
      ...>   length: 3,
      ...>   columns: [
      ...>     %Arrow.Array.Int32{
      ...>       length: 3,
      ...>       null_count: 0,
      ...>       values: Arrow.Buffer.pack_primitive([1, 2, 3], :int32)
      ...>     }
      ...>   ]
      ...> }
      iex> stream = Arrow.Ipc.Stream.encode(schema, [batch])
      iex> {:ok, %{batches: [decoded]}} = Arrow.Ipc.Stream.decode(stream)
      iex> Arrow.Logical.to_list(hd(decoded.columns))
      [1, 2, 3]
  """
end
