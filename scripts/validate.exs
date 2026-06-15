# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
# Archery integration CLI mode: validate.
#
#     mix run scripts/validate.exs --json <path> --arrow <path>
#
# Decodes both inputs through our pipeline and asserts they're
# logically equivalent via Arrow.Logical.payloads_equivalent?/2. Exits
# 0 on success, raises a Mix.Error (non-zero exit) with a brief diff on
# mismatch. Used by archery's cross-language test runner via
# bin/arrow-json-integration-validate.

{opts, _} = OptionParser.parse!(System.argv(), strict: [json: :string, arrow: :string])

json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")
arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")

decode! = fn path, decode ->
  case path |> File.read!() |> decode.() do
    {:ok, payload} -> payload
    {:error, e} -> Mix.raise("failed to decode #{path}: #{Exception.message(e)}")
  end
end

from_json = decode!.(json_path, &Arrow.Json.decode/1)
from_arrow = decode!.(arrow_path, &Arrow.Ipc.File.decode/1)

if Arrow.Logical.payloads_equivalent?(from_json, from_arrow) do
  Mix.shell().info("ok: #{json_path} ↔ #{arrow_path}")
else
  message =
    cond do
      not Arrow.Logical.schemas_equivalent?(from_json.schema, from_arrow.schema) ->
        "schema mismatch between #{json_path} and #{arrow_path}"

      length(from_json.batches) != length(from_arrow.batches) ->
        "batch count mismatch: json has #{length(from_json.batches)}, " <>
          "arrow has #{length(from_arrow.batches)}"

      true ->
        "data mismatch between #{json_path} and #{arrow_path}"
    end

  Mix.raise(message)
end
