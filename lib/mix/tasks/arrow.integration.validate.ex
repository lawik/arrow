defmodule Mix.Tasks.Arrow.Integration.Validate do
  @shortdoc "Compare an Arrow IPC file against its JSON integration fixture"

  @moduledoc """
  Arrow integration test CLI mode: validate.

      mix arrow.integration.validate --json <path> --arrow <path>

  Decodes both inputs through our pipeline and asserts they're
  logically equivalent via `Arrow.Logical.payloads_equivalent?/2`.
  Exits 0 on success, raises a `Mix.Error` (non-zero exit) with a
  brief diff on mismatch. Used by archery's cross-language test
  runner (via the binary shim under `bin/`).
  """

  use Mix.Task

  alias Arrow.Ipc.File, as: IpcFile

  @impl Mix.Task
  def run(argv) do
    {opts, _} = OptionParser.parse!(argv, strict: [json: :string, arrow: :string])

    json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")
    arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")

    from_json =
      json_path
      |> File.read!()
      |> Arrow.Json.decode()
      |> ok_or_raise(json_path)

    from_arrow =
      arrow_path
      |> File.read!()
      |> IpcFile.decode()
      |> ok_or_raise(arrow_path)

    if Arrow.Logical.payloads_equivalent?(from_json, from_arrow) do
      Mix.shell().info("ok: #{json_path} ↔ #{arrow_path}")
    else
      Mix.raise(diff_message(from_json, from_arrow, json_path, arrow_path))
    end
  end

  defp ok_or_raise({:ok, payload}, _path), do: payload

  defp ok_or_raise({:error, e}, path) when is_exception(e),
    do: Mix.raise("failed to decode #{path}: #{Exception.message(e)}")

  defp ok_or_raise({:error, e}, path), do: Mix.raise("failed to decode #{path}: #{inspect(e)}")

  defp diff_message(from_json, from_arrow, json_path, arrow_path) do
    cond do
      not Arrow.Logical.schemas_equivalent?(from_json.schema, from_arrow.schema) ->
        "schema mismatch between #{json_path} and #{arrow_path}"

      length(from_json.batches) != length(from_arrow.batches) ->
        "batch count mismatch: json has #{length(from_json.batches)}, " <>
          "arrow has #{length(from_arrow.batches)}"

      true ->
        "data mismatch between #{json_path} and #{arrow_path}"
    end
  end
end
