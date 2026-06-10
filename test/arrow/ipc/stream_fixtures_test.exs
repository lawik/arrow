defmodule Arrow.Ipc.StreamFixturesTest do
  @moduledoc """
  Cross-language conformance via the `arrow-testing` `.stream` fixtures.

  Each test pairs a `.stream` file (FlatBuffers + binary body produced by
  another Arrow implementation) with its matching `.json.gz` fixture
  (the canonical Arrow integration JSON). We decode both through our
  pipeline and assert they agree:

  - schema by exact structural equality
  - batches by null-aware logical equality (`Arrow.Logical.batches_equal?/2`),
    which compares per-slot logical values while ignoring byte
    differences at null positions or in validity-bitmap padding.

  Decode failures are soft skips only for
  `{:error, %Arrow.DecodeError{kind: :unsupported}}` — the library
  deliberately rejecting a format feature; `:malformed` errors and
  anything else flunk. When `--include fixtures` is given but the corpus
  is absent, the placeholder test flunks rather than passing green.
  """

  use ExUnit.Case, async: true

  @moduletag :fixtures

  @fixtures_root Path.expand("../../../priv/arrow-testing", __DIR__)

  fixture_dirs =
    Path.wildcard(Path.join(@fixtures_root, "data/arrow-ipc-stream/integration/*-littleendian"))

  # Fixtures with intentional upstream divergence between `.stream` and
  # `.json.gz` that we *don't* normalize away. Not bugs on our side; the
  # source files genuinely differ in producer-visible state.
  #
  # - generated_map_non_canonical: the IPC producer canonicalizes the Map
  #   entries child name to "entries" while the JSON fixture deliberately
  #   keeps a non-standard name.
  upstream_divergent = [
    "generated_map_non_canonical.stream"
  ]

  stream_paths =
    fixture_dirs
    |> Enum.flat_map(&Path.wildcard(Path.join(&1, "*.stream")))
    |> Enum.reject(fn p ->
      Enum.any?(upstream_divergent, &String.ends_with?(p, &1))
    end)

  if stream_paths == [] do
    test "arrow-testing corpus is present" do
      flunk("""
      `--include fixtures` was given, but no fixtures were found under
      #{@fixtures_root}.
      Run `mix arrow.testing.fixtures` to populate it.
      """)
    end
  else
    for path <- stream_paths do
      name = Path.relative_to(path, @fixtures_root)
      json_path = String.replace_suffix(path, ".stream", ".json.gz")

      test "stream ↔ json logically equal: #{name}" do
        stream_bin = File.read!(unquote(path))
        json_bin = unquote(json_path) |> File.read!() |> :zlib.gunzip()

        with {:ok, from_stream} <- safe_decode(:stream, stream_bin),
             {:ok, from_json} <- safe_decode(:json, json_bin) do
          assert Arrow.Logical.payloads_equivalent?(from_stream, from_json),
                 "payloads diverged between .stream and .json.gz for #{unquote(name)}"
        else
          {:skip, msg} ->
            IO.puts(:stderr, "  ⚠ skipped #{unquote(name)}: #{msg}")
        end
      end
    end

    defp safe_decode(:stream, bin), do: classify(:stream, Arrow.Ipc.Stream.decode(bin))
    defp safe_decode(:json, bin), do: classify(:json, Arrow.Json.decode(bin))

    defp classify(source, result) do
      case result do
        {:ok, payload} ->
          {:ok, payload}

        {:error, %Arrow.DecodeError{kind: :unsupported, message: msg}} ->
          {:skip, "#{source}: #{msg}"}

        # :malformed DecodeErrors and anything else are genuine failures.
        {:error, other} ->
          flunk("#{source} decode failed: #{inspect(other)}")
      end
    end
  end
end
