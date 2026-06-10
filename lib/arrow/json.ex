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
  Reads a JSON document (or in-memory map) into a schema, dictionaries
  registry, and list of record batches.

  Gzipped input (the arrow-testing fixtures ship as `.json.gz`) is
  detected via the gzip magic bytes and decompressed transparently;
  the magic can never start a valid JSON document.
  """
  @spec decode(binary() | map()) ::
          {:ok,
           %{
             schema: Arrow.Schema.t(),
             dictionaries: %{optional(non_neg_integer()) => Arrow.Array.t()},
             batches: [Arrow.RecordBatch.t()]
           }}
          | {:error, term()}
  def decode(<<0x1F, 0x8B, _::binary>> = gzipped) do
    decode(:zlib.gunzip(gzipped))
  rescue
    e in ErlangError -> {:error, e}
  end

  def decode(json) when is_binary(json) do
    with {:ok, decoded} <- Jason.decode(json) do
      decode(decoded)
    end
  end

  def decode(%{} = map), do: Reader.read(map)

  @doc """
  Encodes a schema plus record batches (and optional dictionaries
  registry) into the Arrow integration JSON form.
  """
  @spec encode(
          Arrow.Schema.t(),
          [Arrow.RecordBatch.t()],
          %{optional(non_neg_integer()) => Arrow.Array.t()}
        ) :: iodata()
  def encode(%Arrow.Schema{} = schema, batches, dictionaries \\ %{})
      when is_list(batches) and is_map(dictionaries) do
    schema
    |> Writer.write(batches, dictionaries)
    |> Jason.encode_to_iodata!()
  end
end
