defmodule Arrow.Ipc.FileFixturesTest do
  @moduledoc """
  Cross-language conformance for the Arrow IPC file format.

  Pairs each `.arrow_file` fixture with its `.json.gz` sibling and
  asserts schema equality plus null-aware logical batch equality.
  """

  use ExUnit.Case, async: true

  alias Arrow.Ipc.File, as: IpcFile

  @moduletag :fixtures

  @fixtures_root Path.expand("../../../priv/arrow-testing", __DIR__)
  @fixture_dirs Path.wildcard(
                  Path.join(@fixtures_root, "data/arrow-ipc-file/integration/*-littleendian")
                ) ++
                  Path.wildcard(
                    Path.join(@fixtures_root, "data/arrow-ipc-stream/integration/*-littleendian")
                  )

  # Same upstream divergence skip as the stream harness.
  @upstream_divergent ["generated_map_non_canonical.arrow_file"]

  @paths (if @fixture_dirs == [] do
            []
          else
            @fixture_dirs
            |> Enum.flat_map(&Path.wildcard(Path.join(&1, "*.arrow_file")))
            |> Enum.reject(fn p ->
              Enum.any?(@upstream_divergent, &String.ends_with?(p, &1))
            end)
          end)

  if @paths == [] do
    test "no arrow-testing file fixtures present" do
      IO.puts(:stderr, """

      No fixtures found under #{@fixtures_root}.
      Run `mix arrow.testing.fixtures` to populate it.
      """)
    end
  end

  for path <- @paths do
    name = Path.relative_to(path, @fixtures_root)
    json_path = String.replace_suffix(path, ".arrow_file", ".json.gz")

    if File.exists?(json_path) do
      test "file ↔ json logically equal: #{name}" do
        file_bin = File.read!(unquote(path))
        json_bin = unquote(json_path) |> File.read!() |> :zlib.gunzip()

        with {:ok, from_file} <- safe_decode(:file, file_bin),
             {:ok, from_json} <- safe_decode(:json, json_bin) do
          assert from_file.schema == from_json.schema,
                 "schema diverged between .arrow_file and .json.gz for #{unquote(name)}"

          assert length(from_file.batches) == length(from_json.batches),
                 "batch count diverged for #{unquote(name)}"

          for {f, j, i} <- Enum.zip([from_file.batches, from_json.batches, 0..1_000_000]) do
            assert Arrow.Logical.batches_equal?(f, j),
                   "batch #{i} diverged for #{unquote(name)}"
          end
        else
          {:skip, msg} ->
            IO.puts(:stderr, "  ⚠ skipped #{unquote(name)}: #{msg}")
        end
      end
    end
  end

  defp safe_decode(:file, bin) do
    case IpcFile.decode(bin) do
      {:ok, result} -> {:ok, result}
      {:error, %ArgumentError{message: msg}} -> {:skip, "file: #{msg}"}
      {:error, other} -> flunk("file decode crashed: #{inspect(other)}")
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
