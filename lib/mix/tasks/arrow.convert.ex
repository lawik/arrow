# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Arrow.Convert do
  @shortdoc "Convert between the Arrow IPC file and stream formats"

  @moduledoc """
  Converts an Arrow IPC file to the streaming format or vice versa,
  preserving schema, record batches, and dictionaries.

      mix arrow.convert input.arrow output.stream
      mix arrow.convert input.stream output.arrow

  The input format is auto-detected: IPC files start with the `ARROW1`
  magic, anything else is decoded as a stream. The output is the
  opposite format by default; pass `--to file` or `--to stream` to
  pick explicitly (e.g. to normalize a stream to a fresh stream).
  Exits non-zero with a readable message on malformed or unsupported
  input.
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, args} = OptionParser.parse!(argv, strict: [to: :string])

    {in_path, out_path} =
      case args do
        [in_path, out_path] -> {in_path, out_path}
        _ -> Mix.raise("usage: mix arrow.convert <input> <output> [--to file|stream]")
      end

    binary = File.read!(in_path)
    in_format = detect(binary)
    out_format = out_format(opts, in_format)

    payload = decode(in_format, binary, in_path)

    out_path |> Path.dirname() |> File.mkdir_p!()
    File.write!(out_path, encode(out_format, payload))

    Mix.shell().info(
      "wrote #{out_path} (#{out_format} format, #{length(payload.batches)} batch(es), " <>
        "#{map_size(payload.dictionaries)} dictionary(ies))"
    )
  end

  defp detect(<<"ARROW1", 0, 0, _::binary>>), do: :file
  defp detect(_), do: :stream

  defp out_format(opts, in_format) do
    case Keyword.get(opts, :to) do
      nil -> opposite(in_format)
      "file" -> :file
      "stream" -> :stream
      other -> Mix.raise(~s(--to must be "file" or "stream", got: #{other}))
    end
  end

  defp opposite(:file), do: :stream
  defp opposite(:stream), do: :file

  defp decode(format, binary, path) do
    decode = decoder(format)

    case decode.(binary) do
      {:ok, payload} -> payload
      {:error, e} -> Mix.raise("failed to decode #{path}: #{Exception.message(e)}")
    end
  end

  defp decoder(:file), do: &Arrow.Ipc.File.decode/1
  defp decoder(:stream), do: &Arrow.Ipc.Stream.decode/1

  defp encode(:file, %{schema: schema, batches: batches, dictionaries: dicts}),
    do: Arrow.Ipc.File.encode(schema, batches, dicts)

  defp encode(:stream, %{schema: schema, batches: batches, dictionaries: dicts}),
    do: Arrow.Ipc.Stream.encode(schema, batches, dicts)
end
