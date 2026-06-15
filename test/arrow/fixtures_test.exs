# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.FixturesTest do
  @moduledoc """
  Round-trips every JSON integration fixture in `priv/arrow-testing/`.

  These tests are tagged `:fixtures` and excluded from the default `mix test`
  run. Populate the fixtures first with `scripts/fetch_fixtures.sh`, then run:

      mix test --include fixtures

  Each fixture exercises `Arrow.Json.decode → encode → decode` and asserts
  that the second decode reproduces the first exactly — schema, batches, and
  dictionary registry. Fixtures are stored gzipped in `apache/arrow-testing`,
  so the harness transparently inflates `.json.gz` files.

  Fixtures using types the library deliberately rejects (Union,
  BinaryView/Utf8View, ListView, RunEndEncoded, ...) decode to
  `{:error, %Arrow.DecodeError{kind: :unsupported}}`; those are soft skips
  so the suite signals *coverage* rather than failure. Any other decode
  error flunks. When `--include fixtures` is given but the corpus is
  absent, the placeholder test flunks rather than passing green.
  """

  use ExUnit.Case, async: true

  @moduletag :fixtures

  @fixtures_root Path.expand("../../priv/arrow-testing", __DIR__)

  fixture_paths =
    Path.wildcard(Path.join(@fixtures_root, "data/arrow-ipc-stream/integration/**/*.json.gz")) ++
      Path.wildcard(
        Path.join(@fixtures_root, "data/arrow-ipc-stream/integration/**/*.json_integration")
      )

  if fixture_paths == [] do
    test "arrow-testing corpus is present" do
      flunk("""
      `--include fixtures` was given, but no fixtures were found at
      #{@fixtures_root}.
      Run `scripts/fetch_fixtures.sh` to populate it.
      """)
    end
  else
    for path <- fixture_paths do
      name = Path.relative_to(path, @fixtures_root)

      test "round-trip: #{name}" do
        json = read_fixture(unquote(path))

        case Arrow.Json.decode(json) do
          {:ok, %{schema: schema, dictionaries: dicts, batches: batches}} ->
            encoded = schema |> Arrow.Json.encode(batches, dicts) |> IO.iodata_to_binary()
            {:ok, redecoded} = Arrow.Json.decode(encoded)
            assert redecoded.schema == schema
            assert redecoded.batches == batches
            assert redecoded.dictionaries == dicts

          {:error, %Arrow.DecodeError{kind: :unsupported, message: msg}} ->
            IO.puts(:stderr, "  ⚠ unsupported in #{unquote(name)}: #{msg}")

          # :malformed DecodeErrors and anything else are genuine failures.
          {:error, other} ->
            flunk("decode failed for #{unquote(name)}: #{inspect(other)}")
        end
      end
    end

    defp read_fixture(path) do
      bin = File.read!(path)
      if String.ends_with?(path, ".gz"), do: :zlib.gunzip(bin), else: bin
    end
  end
end
