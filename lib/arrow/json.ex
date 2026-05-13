defmodule Arrow.Json do
  @moduledoc """
  Arrow integration test JSON format.

  Arrow defines a [JSON
  form](https://arrow.apache.org/docs/format/Integration.html#json-test-data-format)
  used by `apache/arrow:dev/archery` to drive cross-language conformance tests.
  Every primitive type has an unambiguous JSON representation, validity is
  encoded as `0`/`1` arrays, and offsets are explicit.

  The reader is in `Arrow.Json.Reader`; the writer in `Arrow.Json.Writer`. This
  module exposes thin shortcuts that round-trip via `Jason`.
  """

  alias Arrow.Json.{Reader, Writer}

  @doc """
  Reads a JSON document (or in-memory map) into a schema plus a list of
  record batches.
  """
  @spec decode(binary() | map()) ::
          {:ok, %{schema: Arrow.Schema.t(), batches: [Arrow.RecordBatch.t()]}}
          | {:error, term()}
  def decode(json) when is_binary(json) do
    with {:ok, decoded} <- Jason.decode(json) do
      decode(decoded)
    end
  end

  def decode(%{} = map), do: Reader.read(map)

  @doc """
  Encodes a schema plus record batches into the Arrow integration JSON form.
  """
  @spec encode(Arrow.Schema.t(), [Arrow.RecordBatch.t()]) :: iodata()
  def encode(%Arrow.Schema{} = schema, batches) when is_list(batches) do
    schema
    |> Writer.write(batches)
    |> Jason.encode_to_iodata!()
  end
end
