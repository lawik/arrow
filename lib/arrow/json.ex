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

  ## Errors

  `decode/1` returns `{:ok, payload}` or `{:error, %Arrow.DecodeError{}}`
  with kind `:unsupported` (the input uses a feature this library
  deliberately rejects) or `:malformed` (the input is corrupt, truncated,
  or internally inconsistent — including invalid gzip or JSON).
  `decode!/1` raises the same error.
  """

  alias Arrow.Json.{Reader, Writer}

  @typedoc "Everything a decoded document carries: schema, dictionary registry, batches."
  @type payload :: %{
          schema: Arrow.Schema.t(),
          dictionaries: %{optional(non_neg_integer()) => Arrow.Array.t()},
          batches: [Arrow.RecordBatch.t()]
        }

  @doc """
  Reads a JSON document (or in-memory map) into a schema, dictionaries
  registry, and list of record batches.

  Gzipped input (the arrow-testing fixtures ship as `.json.gz`) is
  detected via the gzip magic bytes and decompressed transparently;
  the magic can never start a valid JSON document.
  """
  @spec decode(binary() | map()) :: {:ok, payload()} | {:error, Arrow.DecodeError.t()}
  def decode(<<0x1F, 0x8B, _::binary>> = gzipped) do
    decode(:zlib.gunzip(gzipped))
  rescue
    e in ErlangError ->
      {:error,
       %Arrow.DecodeError{kind: :malformed, message: "invalid gzip: " <> Exception.message(e)}}
  end

  def decode(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, decoded} ->
        decode(decoded)

      {:error, %Jason.DecodeError{} = e} ->
        {:error,
         %Arrow.DecodeError{kind: :malformed, message: "invalid JSON: " <> Exception.message(e)}}
    end
  end

  def decode(%{} = map), do: Reader.read(map)

  @doc """
  Like `decode/1`, but returns the payload directly and raises
  `Arrow.DecodeError` on failure.
  """
  @spec decode!(binary() | map()) :: payload()
  def decode!(input) do
    case decode(input) do
      {:ok, payload} -> payload
      {:error, %Arrow.DecodeError{} = e} -> raise e
    end
  end

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
