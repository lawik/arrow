defmodule Mix.Tasks.Arrow.IntegrationTasksTest do
  @moduledoc """
  End-to-end coverage of the archery CLI tasks, with emphasis on the
  dictionary path: `test/golden/dictionary.arrow` (pyarrow-produced)
  carries one DictionaryBatch, which must survive both directions of
  the JSON ↔ IPC conversion.
  """

  use ExUnit.Case, async: false

  alias Arrow.Ipc.File, as: IpcFile

  @golden_arrow Path.expand("../../golden/dictionary.arrow", __DIR__)

  defp golden_payload do
    {:ok, payload} = @golden_arrow |> File.read!() |> IpcFile.decode()
    assert map_size(payload.dictionaries) == 1
    payload
  end

  @tag :tmp_dir
  test "json_to_arrow threads dictionaries into the IPC file", %{tmp_dir: tmp} do
    payload = golden_payload()
    json_path = Path.join(tmp, "dictionary.json")
    arrow_path = Path.join(tmp, "dictionary.arrow")

    File.write!(
      json_path,
      Arrow.Json.encode(payload.schema, payload.batches, payload.dictionaries)
    )

    Mix.Task.rerun("arrow.integration.json_to_arrow", [
      "--json",
      json_path,
      "--arrow",
      arrow_path
    ])

    {:ok, decoded} = arrow_path |> File.read!() |> IpcFile.decode()
    assert map_size(decoded.dictionaries) == 1
    assert Arrow.Logical.payloads_equivalent?(payload, decoded)
  end

  @tag :tmp_dir
  test "json_to_arrow transparently gunzips its JSON input", %{tmp_dir: tmp} do
    payload = golden_payload()
    json_path = Path.join(tmp, "dictionary.json.gz")
    arrow_path = Path.join(tmp, "dictionary.arrow")

    json = Arrow.Json.encode(payload.schema, payload.batches, payload.dictionaries)
    File.write!(json_path, json |> IO.iodata_to_binary() |> :zlib.gzip())

    Mix.Task.rerun("arrow.integration.json_to_arrow", [
      "--json",
      json_path,
      "--arrow",
      arrow_path
    ])

    {:ok, decoded} = arrow_path |> File.read!() |> IpcFile.decode()
    assert Arrow.Logical.payloads_equivalent?(payload, decoded)
  end

  @tag :tmp_dir
  test "arrow_to_json threads dictionaries into the JSON fixture", %{tmp_dir: tmp} do
    json_path = Path.join(tmp, "dictionary.json")

    Mix.Task.rerun("arrow.integration.arrow_to_json", [
      "--arrow",
      @golden_arrow,
      "--json",
      json_path
    ])

    {:ok, decoded} = json_path |> File.read!() |> Arrow.Json.decode()
    assert map_size(decoded.dictionaries) == 1
    assert Arrow.Logical.payloads_equivalent?(golden_payload(), decoded)
  end

  @tag :tmp_dir
  test "file_to_stream and stream_to_file round-trip with dictionaries", %{tmp_dir: tmp} do
    stream_path = Path.join(tmp, "dictionary.stream")
    arrow_path = Path.join(tmp, "dictionary.arrow")

    Mix.Task.rerun("arrow.integration.file_to_stream", [
      "--arrow",
      @golden_arrow,
      "--stream",
      stream_path
    ])

    {:ok, from_stream} = stream_path |> File.read!() |> Arrow.Ipc.Stream.decode()
    assert map_size(from_stream.dictionaries) == 1

    Mix.Task.rerun("arrow.integration.stream_to_file", [
      "--stream",
      stream_path,
      "--arrow",
      arrow_path
    ])

    {:ok, decoded} = arrow_path |> File.read!() |> IpcFile.decode()
    assert map_size(decoded.dictionaries) == 1
    assert Arrow.Logical.payloads_equivalent?(golden_payload(), decoded)
  end

  @tag :tmp_dir
  test "malformed input raises Mix.Error, not MatchError", %{tmp_dir: tmp} do
    bad_path = Path.join(tmp, "bad.json")
    File.write!(bad_path, "not json")

    assert_raise Mix.Error, ~r/failed to decode/, fn ->
      Mix.Task.rerun("arrow.integration.json_to_arrow", [
        "--json",
        bad_path,
        "--arrow",
        Path.join(tmp, "out.arrow")
      ])
    end
  end

  test "invalid switches are rejected instead of swallowed" do
    # OptionParser.ParseError is re-wrapped by Mix.Task.run; either way
    # the task aborts on the typo instead of reporting "--json is required".
    assert_raise Mix.Error, ~r/--josn/, fn ->
      Mix.Task.rerun("arrow.integration.json_to_arrow", ["--josn", "x"])
    end
  end
end
