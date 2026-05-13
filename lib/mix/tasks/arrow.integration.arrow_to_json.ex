defmodule Mix.Tasks.Arrow.Integration.ArrowToJson do
  @shortdoc "Read an Arrow IPC file; write an Arrow integration JSON fixture"

  @moduledoc """
  Arrow integration test CLI mode: Arrow IPC file → JSON.

      mix arrow.integration.arrow_to_json --arrow <path> --json <path>

  Reads the Arrow IPC file at `--arrow`, decodes it via
  `Arrow.Ipc.File`, encodes the schema + batches as integration JSON
  via `Arrow.Json`, and writes the result to `--json`. Used by
  archery's cross-language test runner (via the binary shim under
  `bin/`).
  """

  use Mix.Task

  alias Arrow.Ipc.File, as: IpcFile

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [arrow: :string, json: :string])

    arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")
    json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")

    {:ok, %{schema: schema, batches: batches}} =
      arrow_path
      |> File.read!()
      |> IpcFile.decode()

    json_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(json_path, Arrow.Json.encode(schema, batches))
  end
end
