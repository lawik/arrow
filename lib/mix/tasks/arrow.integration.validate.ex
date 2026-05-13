defmodule Mix.Tasks.Arrow.Integration.Validate do
  @shortdoc "Compare an Arrow IPC file against its JSON integration fixture"

  @moduledoc """
  Arrow integration test CLI mode: validate.

      mix arrow.integration.validate --json <path> --arrow <path>

  Decodes both inputs through our pipeline and asserts they're
  logically equivalent via `Arrow.Logical.batches_equal?/2`. Exits 0
  on success, raises a `Mix.Error` (non-zero exit) with a brief diff
  on mismatch. Used by archery's cross-language test runner (via the
  binary shim under `bin/`).
  """

  use Mix.Task

  alias Arrow.Ipc.File, as: IpcFile

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [json: :string, arrow: :string])

    json_path = Keyword.get(opts, :json) || Mix.raise("--json <path> is required")
    arrow_path = Keyword.get(opts, :arrow) || Mix.raise("--arrow <path> is required")

    {:ok, from_json} =
      json_path
      |> File.read!()
      |> maybe_gunzip()
      |> Arrow.Json.decode()

    {:ok, from_arrow} =
      arrow_path
      |> File.read!()
      |> IpcFile.decode()

    cond do
      from_json.schema != from_arrow.schema ->
        Mix.raise("schema mismatch between #{json_path} and #{arrow_path}")

      length(from_json.batches) != length(from_arrow.batches) ->
        Mix.raise(
          "batch count mismatch: json has #{length(from_json.batches)}, " <>
            "arrow has #{length(from_arrow.batches)}"
        )

      true ->
        from_json.batches
        |> Enum.zip(from_arrow.batches)
        |> Enum.with_index()
        |> Enum.each(fn {{a, b}, i} ->
          unless Arrow.Logical.batches_equal?(a, b) do
            Mix.raise(
              "batch #{i} diverged between #{json_path} and #{arrow_path}"
            )
          end
        end)
    end

    Mix.shell().info("ok: #{json_path} ↔ #{arrow_path}")
  end

  defp maybe_gunzip(<<0x1F, 0x8B, _::binary>> = bin), do: :zlib.gunzip(bin)
  defp maybe_gunzip(bin), do: bin
end
