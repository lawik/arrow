# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Arrow.ScriptsTest do
  @moduledoc """
  End-to-end coverage of the archery CLI scripts (`scripts/*.exs`),
  with emphasis on the dictionary path: `test/golden/dictionary.arrow`
  (pyarrow-produced) carries one DictionaryBatch, which must survive
  both directions of the JSON ↔ IPC conversion.

  Scripts read `System.argv/0`, so they're executed in-process via
  `Code.eval_file/1` with argv swapped out — the `mix run` plumbing
  itself is exercised by the bin/ shims under archery in CI.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Arrow.Ipc.File, as: IpcFile

  @golden_arrow Path.expand("golden/dictionary.arrow", __DIR__)
  @scripts_dir Path.expand("../scripts", __DIR__)

  defp run_script(script, args) do
    saved = System.argv()
    System.argv(args)

    try do
      Code.eval_file(Path.join(@scripts_dir, script))
    after
      System.argv(saved)
    end
  end

  defp golden_payload do
    {:ok, payload} = @golden_arrow |> File.read!() |> IpcFile.decode()
    assert map_size(payload.dictionaries) == 1
    payload
  end

  @tag :tmp_dir
  test "arrow → json → arrow round-trip threads dictionaries", %{tmp_dir: tmp} do
    json_path = Path.join(tmp, "dictionary.json")
    arrow_path = Path.join(tmp, "dictionary.arrow")

    run_script("arrow_to_json.exs", ["--arrow", @golden_arrow, "--json", json_path])

    {:ok, from_json} = json_path |> File.read!() |> Arrow.Json.decode()
    assert map_size(from_json.dictionaries) == 1

    run_script("json_to_arrow.exs", ["--json", json_path, "--arrow", arrow_path])

    {:ok, decoded} = arrow_path |> File.read!() |> IpcFile.decode()
    assert map_size(decoded.dictionaries) == 1
    assert Arrow.Logical.payloads_equivalent?(golden_payload(), decoded)

    output =
      capture_io(fn ->
        run_script("validate.exs", ["--json", json_path, "--arrow", arrow_path])
      end)

    assert output =~ "ok:"
  end

  @tag :tmp_dir
  test "json_to_arrow transparently gunzips its JSON input", %{tmp_dir: tmp} do
    payload = golden_payload()
    json_path = Path.join(tmp, "dictionary.json.gz")
    arrow_path = Path.join(tmp, "dictionary.arrow")

    json = Arrow.Json.encode(payload.schema, payload.batches, payload.dictionaries)
    File.write!(json_path, json |> IO.iodata_to_binary() |> :zlib.gzip())

    run_script("json_to_arrow.exs", ["--json", json_path, "--arrow", arrow_path])

    {:ok, decoded} = arrow_path |> File.read!() |> IpcFile.decode()
    assert Arrow.Logical.payloads_equivalent?(payload, decoded)
  end

  @tag :tmp_dir
  test "file_to_stream and stream_to_file round-trip with dictionaries", %{tmp_dir: tmp} do
    stream_path = Path.join(tmp, "dictionary.stream")
    arrow_path = Path.join(tmp, "dictionary.arrow")

    run_script("file_to_stream.exs", ["--arrow", @golden_arrow, "--stream", stream_path])

    {:ok, from_stream} = stream_path |> File.read!() |> Arrow.Ipc.Stream.decode()
    assert map_size(from_stream.dictionaries) == 1

    run_script("stream_to_file.exs", ["--stream", stream_path, "--arrow", arrow_path])

    {:ok, decoded} = arrow_path |> File.read!() |> IpcFile.decode()
    assert map_size(decoded.dictionaries) == 1
    assert Arrow.Logical.payloads_equivalent?(golden_payload(), decoded)
  end

  @tag :tmp_dir
  test "validate raises on mismatched inputs", %{tmp_dir: tmp} do
    payload = golden_payload()
    json_path = Path.join(tmp, "one_batch.json")

    File.write!(
      json_path,
      Arrow.Json.encode(payload.schema, payload.batches ++ payload.batches, payload.dictionaries)
    )

    assert_raise Mix.Error, ~r/batch count mismatch/, fn ->
      run_script("validate.exs", ["--json", json_path, "--arrow", @golden_arrow])
    end
  end

  @tag :tmp_dir
  test "malformed input raises Mix.Error, not MatchError", %{tmp_dir: tmp} do
    bad_path = Path.join(tmp, "bad.json")
    File.write!(bad_path, "not json")

    assert_raise Mix.Error, ~r/failed to decode/, fn ->
      run_script("json_to_arrow.exs", [
        "--json",
        bad_path,
        "--arrow",
        Path.join(tmp, "out.arrow")
      ])
    end
  end

  test "invalid switches are rejected instead of swallowed" do
    assert_raise OptionParser.ParseError, ~r/--josn/, fn ->
      run_script("json_to_arrow.exs", ["--josn", "x"])
    end
  end
end
