# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
# Archery integration CLI mode: IPC stream → IPC file.
#
#     mix run scripts/stream_to_file.exs --stream <path> --arrow <path>
#
# Reads the Arrow IPC stream at --stream, decodes it via
# Arrow.Ipc.Stream, re-encodes the schema + dictionaries + batches in
# the file format via Arrow.Ipc.File, and writes the result to --arrow.
# Used by archery's cross-language test runner via
# bin/arrow-stream-to-file.

{opts, _} = OptionParser.parse!(System.argv(), strict: [stream: :string, arrow: :string])

stream_path = Keyword.get(opts, :stream) || Mix.raise("--stream <path> is required")
arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")

decode! = fn path, decode ->
  case path |> File.read!() |> decode.() do
    {:ok, payload} -> payload
    {:error, e} -> Mix.raise("failed to decode #{path}: #{Exception.message(e)}")
  end
end

payload = decode!.(stream_path, &Arrow.Ipc.Stream.decode/1)

arrow_path |> Path.dirname() |> File.mkdir_p!()

File.write!(
  arrow_path,
  Arrow.Ipc.File.encode(payload.schema, payload.batches, payload.dictionaries)
)
