# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
# Archery integration CLI mode: Arrow IPC file → JSON.
#
#     mix run scripts/arrow_to_json.exs --arrow <path> --json <path>
#
# Reads the Arrow IPC file at --arrow, decodes it via Arrow.Ipc.File,
# encodes the schema + dictionaries + batches as integration JSON via
# Arrow.Json, and writes the result to --json. Used by archery's
# cross-language test runner via bin/arrow-json-integration-json.

{opts, _} = OptionParser.parse!(System.argv(), strict: [arrow: :string, json: :string])

arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")
json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")

decode! = fn path, decode ->
  case path |> File.read!() |> decode.() do
    {:ok, payload} -> payload
    {:error, e} -> Mix.raise("failed to decode #{path}: #{Exception.message(e)}")
  end
end

payload = decode!.(arrow_path, &Arrow.Ipc.File.decode/1)

json_path |> Path.dirname() |> File.mkdir_p!()

File.write!(
  json_path,
  Arrow.Json.encode(payload.schema, payload.batches, payload.dictionaries)
)
