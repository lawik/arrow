# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Arrow.ConvertTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Arrow.Ipc.File, as: IpcFile

  @golden_arrow Path.expand("../../golden/dictionary.arrow", __DIR__)

  defp golden_payload do
    {:ok, payload} = @golden_arrow |> File.read!() |> IpcFile.decode()
    assert map_size(payload.dictionaries) == 1
    payload
  end

  defp convert(args) do
    capture_io(fn -> Mix.Task.rerun("arrow.convert", args) end)
  end

  @tag :tmp_dir
  test "file → stream → file round-trip preserves dictionaries", %{tmp_dir: tmp} do
    stream_path = Path.join(tmp, "out.stream")
    arrow_path = Path.join(tmp, "back.arrow")

    output = convert([@golden_arrow, stream_path])
    assert output =~ "stream format"

    {:ok, from_stream} = stream_path |> File.read!() |> Arrow.Ipc.Stream.decode()
    assert map_size(from_stream.dictionaries) == 1

    convert([stream_path, arrow_path])

    assert <<"ARROW1", 0, 0, _::binary>> = File.read!(arrow_path)
    {:ok, decoded} = arrow_path |> File.read!() |> IpcFile.decode()
    assert Arrow.Logical.payloads_equivalent?(golden_payload(), decoded)
  end

  @tag :tmp_dir
  test "--to overrides the default direction", %{tmp_dir: tmp} do
    out_path = Path.join(tmp, "still_a_file.arrow")

    convert([@golden_arrow, out_path, "--to", "file"])

    assert <<"ARROW1", 0, 0, _::binary>> = File.read!(out_path)
  end

  @tag :tmp_dir
  test "rejects an unknown --to value", %{tmp_dir: tmp} do
    assert_raise Mix.Error, ~r/--to must be/, fn ->
      Mix.Task.rerun("arrow.convert", [@golden_arrow, Path.join(tmp, "out"), "--to", "csv"])
    end
  end

  @tag :tmp_dir
  test "malformed input raises Mix.Error", %{tmp_dir: tmp} do
    bad_path = Path.join(tmp, "bad.stream")
    File.write!(bad_path, "garbage")

    assert_raise Mix.Error, ~r/failed to decode/, fn ->
      Mix.Task.rerun("arrow.convert", [bad_path, Path.join(tmp, "out.arrow")])
    end
  end

  test "missing arguments raise usage" do
    assert_raise Mix.Error, ~r/usage:/, fn ->
      Mix.Task.rerun("arrow.convert", [@golden_arrow])
    end
  end
end
