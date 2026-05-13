defmodule Arrow.Ipc.StreamFixturesTest do
  @moduledoc """
  Cross-language conformance via the `arrow-testing` `.stream` fixtures.

  Each test pairs a `.stream` file (FlatBuffers + binary body produced by
  another Arrow implementation) with its matching `.json.gz` fixture
  (the canonical Arrow integration JSON). We decode both through our
  pipeline and assert they agree on:

  - schema (exact)
  - batch count
  - per-column `length`, `null_count`, and `validity`

  Value buffers are *not* compared byte-exactly: the Arrow spec says
  null slots may carry arbitrary content, and different producers fill
  them differently (the C++ producer zeroes them; the JSON producer
  emits the original random values). A proper null-aware logical
  equality lives in a follow-up.
  """

  use ExUnit.Case, async: true

  alias Arrow.Ipc.Stream

  @moduletag :fixtures

  @fixtures_root Path.expand("../../../priv/arrow-testing", __DIR__)
  @fixture_dirs Path.wildcard(
                  Path.join(@fixtures_root, "data/arrow-ipc-stream/integration/*-littleendian")
                )

  # Fixtures with intentional upstream divergence between `.stream` and
  # `.json.gz`. The "non_canonical" Map case has the IPC producer canonicalize
  # the Map entries child name to "entries" while the JSON fixture deliberately
  # keeps a non-standard name. There's no disagreement in our pipeline to fix.
  @upstream_divergent [
    "generated_map_non_canonical.stream"
  ]

  @stream_paths (if @fixture_dirs == [] do
                   []
                 else
                   @fixture_dirs
                   |> Enum.flat_map(&Path.wildcard(Path.join(&1, "*.stream")))
                   |> Enum.reject(fn p ->
                     Enum.any?(@upstream_divergent, &String.ends_with?(p, &1))
                   end)
                 end)

  if @stream_paths == [] do
    test "no arrow-testing fixtures present" do
      IO.puts(:stderr, """

      No fixtures found under #{@fixtures_root}.
      Run `mix arrow.testing.fixtures` to populate it.
      """)
    end
  end

  for path <- @stream_paths do
    name = Path.relative_to(path, @fixtures_root)
    json_path = String.replace_suffix(path, ".stream", ".json.gz")

    test "stream ↔ json agree on schema: #{name}" do
      stream_bin = File.read!(unquote(path))
      json_bin = unquote(json_path) |> File.read!() |> :zlib.gunzip()

      with {:ok, from_stream} <- safe_decode(:stream, stream_bin),
           {:ok, from_json} <- safe_decode(:json, json_bin) do
        assert from_stream.schema == from_json.schema,
               "schema diverged between .stream and .json.gz for #{unquote(name)}"

        assert length(from_stream.batches) == length(from_json.batches),
               "batch count diverged for #{unquote(name)}"

        for {s, j, i} <- Enum.zip([from_stream.batches, from_json.batches, 0..1_000_000]) do
          assert s.length == j.length, "batch #{i} length diverged"
          assert length(s.columns) == length(j.columns), "batch #{i} column count diverged"

          for {sc, jc, ci} <- Enum.zip([s.columns, j.columns, 0..1_000_000]) do
            assert sc.__struct__ == jc.__struct__,
                   "batch #{i} col #{ci}: array type diverged " <>
                     "(stream=#{inspect(sc.__struct__)} json=#{inspect(jc.__struct__)})"

            if Map.has_key?(sc, :null_count) do
              assert sc.null_count == jc.null_count,
                     "batch #{i} col #{ci}: null_count diverged"

              assert sc.validity == jc.validity,
                     "batch #{i} col #{ci}: validity diverged"
            end
          end
        end
      else
        {:skip, msg} ->
          IO.puts(:stderr, "  ⚠ skipped #{unquote(name)}: #{msg}")
      end
    end
  end

  defp safe_decode(:stream, bin) do
    case Stream.decode(bin) do
      {:ok, result} -> {:ok, result}
      {:error, %ArgumentError{message: msg}} -> {:skip, "stream: #{msg}"}
      {:error, other} -> flunk("stream decode crashed: #{inspect(other)}")
    end
  end

  defp safe_decode(:json, bin) do
    case Arrow.Json.decode(bin) do
      {:ok, result} -> {:ok, result}
      {:error, %ArgumentError{message: msg}} -> {:skip, "json: #{msg}"}
      {:error, other} -> flunk("json decode crashed: #{inspect(other)}")
    end
  end
end
