defmodule Mix.Tasks.Arrow.Integration.JsonToArrow do
  @shortdoc "Read an Arrow integration JSON fixture; write an Arrow IPC file"

  @moduledoc """
  Arrow integration test CLI mode: JSON → Arrow IPC file.

      mix arrow.integration.json_to_arrow --json <path> --arrow <path>

  Reads the JSON fixture at `--json`, decodes it via `Arrow.Json`,
  encodes the schema + batches via `Arrow.Ipc.File`, and writes the
  result to `--arrow`. Used by archery's cross-language test runner
  (via the binary shim under `bin/`).
  """

  use Mix.Task

  alias Arrow.Ipc.File, as: IpcFile

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [json: :string, arrow: :string])

    json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")
    arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")

    {:ok, %{schema: schema, batches: batches}} =
      json_path
      |> File.read!()
      |> maybe_gunzip()
      |> Arrow.Json.decode()

    arrow_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(arrow_path, IpcFile.encode(schema, batches))
  end

  defp maybe_gunzip(<<0x1F, 0x8B, _::binary>> = bin), do: :zlib.gunzip(bin)
  defp maybe_gunzip(bin), do: bin
end
