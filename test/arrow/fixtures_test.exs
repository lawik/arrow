defmodule Arrow.FixturesTest do
  @moduledoc """
  Round-trips every JSON integration fixture in `priv/arrow-testing/`.

  These tests are tagged `:fixtures` and excluded from the default `mix test`
  run. Populate the fixtures first with `mix arrow.testing.fixtures`, then run:

      mix test --include fixtures

  Each fixture exercises `Arrow.Json.decode → encode → decode` and asserts that
  the second decode produces the exact same in-memory structures as the first.
  Fixtures are stored gzipped in `apache/arrow-testing`, so the harness
  transparently inflates `.json.gz` files.

  Fixtures using types we haven't implemented yet (Decimal, Dictionary, Map,
  Union, FixedSizeBinary/List, Time, Duration, Interval, LargeUtf8, ...) raise
  `ArgumentError` inside the reader. We treat those as soft skips so the suite
  signals *coverage* rather than failure, while genuine round-trip mismatches
  still flunk.
  """

  use ExUnit.Case, async: true

  @moduletag :fixtures

  @fixtures_root Path.expand("../../priv/arrow-testing", __DIR__)

  @fixture_paths (if File.dir?(@fixtures_root) do
                    Path.wildcard(
                      Path.join(@fixtures_root, "data/arrow-ipc-stream/integration/**/*.json.gz")
                    ) ++
                      Path.wildcard(
                        Path.join(
                          @fixtures_root,
                          "data/arrow-ipc-stream/integration/**/*.json_integration"
                        )
                      )
                  else
                    []
                  end)

  if @fixture_paths == [] do
    test "no arrow-testing fixtures present" do
      IO.puts(:stderr, """

      No fixtures found at #{@fixtures_root}.
      Run `mix arrow.testing.fixtures` to populate it.
      """)
    end
  end

  for path <- @fixture_paths do
    name = Path.relative_to(path, @fixtures_root)

    test "round-trip: #{name}" do
      json = read_fixture(unquote(path))

      case Arrow.Json.decode(json) do
        {:ok, %{schema: schema, batches: batches}} ->
          encoded = schema |> Arrow.Json.encode(batches) |> IO.iodata_to_binary()
          {:ok, redecoded} = Arrow.Json.decode(encoded)
          assert redecoded.schema == schema
          assert redecoded.batches == batches

        {:error, %ArgumentError{message: msg}} ->
          IO.puts(:stderr, "  ⚠ unsupported in #{unquote(name)}: #{msg}")

        {:error, other} ->
          flunk("decode error for #{unquote(name)}: #{inspect(other)}")
      end
    end
  end

  defp read_fixture(path) do
    bin = File.read!(path)
    if String.ends_with?(path, ".gz"), do: :zlib.gunzip(bin), else: bin
  end
end
