defmodule Mix.Tasks.Arrow.Integration.FileToStream do
  @shortdoc "Read an Arrow IPC file; write an Arrow IPC stream"

  @moduledoc """
  Arrow integration test CLI mode: IPC file → IPC stream.

      mix arrow.integration.file_to_stream --arrow <path> --stream <path>

  Reads the Arrow IPC file at `--arrow`, decodes it via
  `Arrow.Ipc.File`, re-encodes the schema + dictionaries + batches in
  the streaming format via `Arrow.Ipc.Stream`, and writes the result
  to `--stream`. Used by archery's cross-language test runner (via the
  binary shim under `bin/`).
  """

  use Mix.Task

  alias Arrow.Ipc.File, as: IpcFile
  alias Arrow.Ipc.Stream, as: IpcStream

  @impl Mix.Task
  def run(argv) do
    {opts, _} = OptionParser.parse!(argv, strict: [arrow: :string, stream: :string])

    arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")
    stream_path = Keyword.get(opts, :stream) || Mix.raise("--stream <path> is required")

    %{schema: schema, dictionaries: dicts, batches: batches} =
      arrow_path
      |> File.read!()
      |> IpcFile.decode()
      |> ok_or_raise(arrow_path)

    stream_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(stream_path, IpcStream.encode(schema, batches, dicts))
  end

  defp ok_or_raise({:ok, payload}, _path), do: payload

  defp ok_or_raise({:error, e}, path) when is_exception(e),
    do: Mix.raise("failed to decode #{path}: #{Exception.message(e)}")

  defp ok_or_raise({:error, e}, path), do: Mix.raise("failed to decode #{path}: #{inspect(e)}")
end
