# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
# Archery integration CLI mode: IPC file → IPC stream.
#
#     mix run scripts/file_to_stream.exs --arrow <path> --stream <path>
#
# Reads the Arrow IPC file at --arrow, decodes it via Arrow.Ipc.File,
# re-encodes the schema + dictionaries + batches in the streaming
# format via Arrow.Ipc.Stream, and writes the result to --stream. Used
# by archery's cross-language test runner via bin/arrow-file-to-stream.

{opts, _} = OptionParser.parse!(System.argv(), strict: [arrow: :string, stream: :string])

arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")
stream_path = Keyword.get(opts, :stream) || Mix.raise("--stream <path> is required")

decode! = fn path, decode ->
  case path |> File.read!() |> decode.() do
    {:ok, payload} -> payload
    {:error, e} -> Mix.raise("failed to decode #{path}: #{Exception.message(e)}")
  end
end

payload = decode!.(arrow_path, &Arrow.Ipc.File.decode/1)

stream_path |> Path.dirname() |> File.mkdir_p!()

File.write!(
  stream_path,
  Arrow.Ipc.Stream.encode(payload.schema, payload.batches, payload.dictionaries)
)
