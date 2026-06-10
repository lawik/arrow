defmodule Mix.Tasks.Arrow.Integration.JsonToArrow do
  @shortdoc "Read an Arrow integration JSON fixture; write an Arrow IPC file"

  @moduledoc """
  Arrow integration test CLI mode: JSON → Arrow IPC file.

      mix arrow.integration.json_to_arrow --json <path> --arrow <path>

  Reads the JSON fixture at `--json` (gzipped or plain), decodes it via
  `Arrow.Json`, encodes the schema + dictionaries + batches via
  `Arrow.Ipc.File`, and writes the result to `--arrow`. Used by
  archery's cross-language test runner (via the binary shim under
  `bin/`).
  """

  use Mix.Task

  alias Arrow.Ipc.File, as: IpcFile

  @impl Mix.Task
  def run(argv) do
    {opts, _} = OptionParser.parse!(argv, strict: [json: :string, arrow: :string])

    json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")
    arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")

    %{schema: schema, dictionaries: dicts, batches: batches} =
      json_path
      |> File.read!()
      |> Arrow.Json.decode()
      |> ok_or_raise(json_path)

    arrow_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(arrow_path, IpcFile.encode(schema, batches, dicts))
  end

  defp ok_or_raise({:ok, payload}, _path), do: payload

  defp ok_or_raise({:error, e}, path) when is_exception(e),
    do: Mix.raise("failed to decode #{path}: #{Exception.message(e)}")

  defp ok_or_raise({:error, e}, path), do: Mix.raise("failed to decode #{path}: #{inspect(e)}")
end
