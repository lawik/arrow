defmodule Arrow.Ipc.FileFixturesTest do
  @moduledoc """
  Cross-language conformance for the Arrow IPC file format.

  Pairs each `.arrow_file` fixture with its `.json.gz` sibling and
  asserts schema equality plus null-aware logical batch equality.

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
    Path.wildcard(Path.join(@fixtures_root, "data/arrow-ipc-file/integration/*-littleendian")) ++
      Path.wildcard(Path.join(@fixtures_root, "data/arrow-ipc-stream/integration/*-littleendian"))

  # Same upstream divergence skip as the stream harness — see
  # stream_fixtures_test.exs for the reasoning per file.
  upstream_divergent = ["generated_map_non_canonical.arrow_file"]

  paths =
    fixture_dirs
    |> Enum.flat_map(&Path.wildcard(Path.join(&1, "*.arrow_file")))
    |> Enum.reject(fn p ->
      Enum.any?(upstream_divergent, &String.ends_with?(p, &1))
    end)

  if paths == [] do
    test "arrow-testing corpus is present" do
      flunk("""
      `--include fixtures` was given, but no file fixtures were found under
      #{@fixtures_root}.
      Run `mix arrow.testing.fixtures` to populate it.
      """)
    end
  else
    for path <- paths do
      name = Path.relative_to(path, @fixtures_root)
      json_path = String.replace_suffix(path, ".arrow_file", ".json.gz")

      if File.exists?(json_path) do
        test "file ↔ json logically equal: #{name}" do
          file_bin = File.read!(unquote(path))
          json_bin = unquote(json_path) |> File.read!() |> :zlib.gunzip()

          with {:ok, from_file} <- safe_decode(:file, file_bin),
               {:ok, from_json} <- safe_decode(:json, json_bin) do
            assert Arrow.Logical.payloads_equivalent?(from_file, from_json),
                   "payloads diverged between .arrow_file and .json.gz for #{unquote(name)}"
          else
            {:skip, msg} ->
              IO.puts(:stderr, "  ⚠ skipped #{unquote(name)}: #{msg}")
          end
        end
      end
    end

    defp safe_decode(:file, bin), do: classify(:file, Arrow.Ipc.File.decode(bin))
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
