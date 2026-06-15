# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Arrow.InspectTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @golden_arrow Path.expand("../../golden/dictionary.arrow", __DIR__)
  @golden_stream Path.expand("../../golden/dictionary.stream", __DIR__)
  @golden_nested Path.expand("../../golden/nested.arrow", __DIR__)

  defp inspect_output(path) do
    capture_io(fn -> Mix.Task.rerun("arrow.inspect", [path]) end)
  end

  test "renders a dictionary-encoded IPC file" do
    output = inspect_output(@golden_arrow)

    assert output =~ "format: file"
    assert output =~ "d: dictionary<utf8, indices=int8, id=0> (nullable)"
    assert output =~ "batches: 1, 6 rows total"
    assert output =~ "[0] 6 rows"
    assert output =~ ~s([0] 3 values, referenced by "d")
  end

  test "auto-detects the streaming format" do
    output = inspect_output(@golden_stream)

    assert output =~ "format: stream"
    assert output =~ "dictionary<utf8"
  end

  test "renders nested types" do
    output = inspect_output(@golden_nested)

    assert output =~ "list<"
    assert output =~ "struct<"
  end

  @tag :tmp_dir
  test "malformed input raises Mix.Error", %{tmp_dir: tmp} do
    bad_path = Path.join(tmp, "bad.arrow")
    File.write!(bad_path, "garbage")

    assert_raise Mix.Error, ~r/failed to decode/, fn ->
      Mix.Task.rerun("arrow.inspect", [bad_path])
    end
  end

  test "missing argument raises usage" do
    assert_raise Mix.Error, ~r/usage:/, fn ->
      Mix.Task.rerun("arrow.inspect", [])
    end
  end
end
