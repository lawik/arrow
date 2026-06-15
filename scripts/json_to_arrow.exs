# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
# Archery integration CLI mode: JSON → Arrow IPC file.
#
#     mix run scripts/json_to_arrow.exs --json <path> --arrow <path>
#
# Reads the JSON fixture at --json (gzipped or plain), decodes it via
# Arrow.Json, encodes the schema + dictionaries + batches via
# Arrow.Ipc.File, and writes the result to --arrow. Used by archery's
# cross-language test runner via bin/arrow-json-integration-arrow.

{opts, _} = OptionParser.parse!(System.argv(), strict: [json: :string, arrow: :string])

json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")
arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")

decode! = fn path, decode ->
  case path |> File.read!() |> decode.() do
    {:ok, payload} -> payload
    {:error, e} -> Mix.raise("failed to decode #{path}: #{Exception.message(e)}")
  end
end

payload = decode!.(json_path, &Arrow.Json.decode/1)

arrow_path |> Path.dirname() |> File.mkdir_p!()

File.write!(
  arrow_path,
  Arrow.Ipc.File.encode(payload.schema, payload.batches, payload.dictionaries)
)
