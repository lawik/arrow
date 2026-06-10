defmodule Mix.Tasks.Arrow.Integration.ArrowToJson do
  @shortdoc "Read an Arrow IPC file; write an Arrow integration JSON fixture"

  @moduledoc """
  Arrow integration test CLI mode: Arrow IPC file → JSON.

      mix arrow.integration.arrow_to_json --arrow <path> --json <path>

  Reads the Arrow IPC file at `--arrow`, decodes it via
  `Arrow.Ipc.File`, encodes the schema + dictionaries + batches as
  integration JSON via `Arrow.Json`, and writes the result to
  `--json`. Used by archery's cross-language test runner (via the
  binary shim under `bin/`).
  """

  use Mix.Task

  alias Arrow.Ipc.File, as: IpcFile

  @impl Mix.Task
  def run(argv) do
    {opts, _} = OptionParser.parse!(argv, strict: [arrow: :string, json: :string])

    arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")
    json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")

    %{schema: schema, dictionaries: dicts, batches: batches} =
      arrow_path
      |> File.read!()
      |> IpcFile.decode()
      |> ok_or_raise(arrow_path)

    json_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(json_path, Arrow.Json.encode(schema, batches, dicts))
  end

  defp ok_or_raise({:ok, payload}, _path), do: payload

  defp ok_or_raise({:error, e}, path) when is_exception(e),
    do: Mix.raise("failed to decode #{path}: #{Exception.message(e)}")

  defp ok_or_raise({:error, e}, path), do: Mix.raise("failed to decode #{path}: #{inspect(e)}")
end
