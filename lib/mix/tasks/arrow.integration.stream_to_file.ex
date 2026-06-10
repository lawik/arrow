defmodule Mix.Tasks.Arrow.Integration.StreamToFile do
  @shortdoc "Read an Arrow IPC stream; write an Arrow IPC file"

  @moduledoc """
  Arrow integration test CLI mode: IPC stream → IPC file.

      mix arrow.integration.stream_to_file --stream <path> --arrow <path>

  Reads the Arrow IPC stream at `--stream`, decodes it via
  `Arrow.Ipc.Stream`, re-encodes the schema + dictionaries + batches
  in the file format via `Arrow.Ipc.File`, and writes the result to
  `--arrow`. Used by archery's cross-language test runner (via the
  binary shim under `bin/`).
  """

  use Mix.Task

  alias Arrow.Ipc.File, as: IpcFile
  alias Arrow.Ipc.Stream, as: IpcStream

  @impl Mix.Task
  def run(argv) do
    {opts, _} = OptionParser.parse!(argv, strict: [stream: :string, arrow: :string])

    stream_path = Keyword.get(opts, :stream) || Mix.raise("--stream <path> is required")
    arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")

    %{schema: schema, dictionaries: dicts, batches: batches} =
      stream_path
      |> File.read!()
      |> IpcStream.decode()
      |> ok_or_raise(stream_path)

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
