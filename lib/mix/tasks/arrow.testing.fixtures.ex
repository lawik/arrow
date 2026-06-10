defmodule Mix.Tasks.Arrow.Testing.Fixtures do
  @shortdoc "Clone or update the apache/arrow-testing repo into priv/arrow-testing"

  @moduledoc """
  Pulls the Arrow project's cross-language integration test fixtures.

  Arrow ships a shared repository of test data at
  https://github.com/apache/arrow-testing. The Elixir test suite uses those
  fixtures to verify that this library round-trips data identically to the
  C++, Rust, Java, Go, JS, and Python implementations.

  Running this task clones that repository into `priv/arrow-testing/` and
  checks out the revision pinned in this module so test runs are
  reproducible; re-running fast-forwards an existing checkout to the pin.
  Once present, `mix test --include fixtures` exercises every JSON
  integration fixture against `Arrow.Json`.

      mix arrow.testing.fixtures

  The repository is fetched shallowly (`--depth 1`) to keep the download
  small. Pass `--full` to fetch the entire history if you need it for a
  specific reason. Pass `--quiet` to suppress git's progress output.
  """

  use Mix.Task

  @repo "https://github.com/apache/arrow-testing.git"
  @target "priv/arrow-testing"
  @revision "9cfebfef8982fb8612e0a2c59059752bd32321a3"

  @impl Mix.Task
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [full: :boolean, quiet: :boolean])

    cond do
      File.dir?(Path.join(@target, ".git")) ->
        update(opts)

      File.exists?(@target) ->
        Mix.raise("#{@target} exists but is not a git checkout; remove it and re-run")

      true ->
        clone(opts)
    end

    Mix.shell().info("Arrow testing fixtures ready at #{@target} (#{@revision})")
  end

  defp clone(opts) do
    File.mkdir_p!("priv")
    Mix.shell().info("Cloning #{@repo} → #{@target} @ #{@revision}")

    args =
      ["clone", "--no-checkout"] ++
        depth(opts) ++ quiet(opts) ++ [@repo, @target]

    run_git(args)
    fetch_and_checkout(opts)
  end

  defp update(opts) do
    if current_revision() == @revision do
      :ok
    else
      Mix.shell().info("Refreshing #{@target} → #{@revision}")
      fetch_and_checkout(opts)
    end
  end

  defp fetch_and_checkout(opts) do
    run_git(["-C", @target, "fetch"] ++ depth(opts) ++ quiet(opts) ++ ["origin", @revision])
    run_git(["-C", @target, "checkout", "--detach"] ++ quiet(opts) ++ [@revision])
  end

  defp current_revision() do
    case System.cmd("git", ["-C", @target, "rev-parse", "HEAD"], stderr_to_stdout: true) do
      {sha, 0} -> String.trim(sha)
      _ -> nil
    end
  end

  defp depth(opts), do: if(opts[:full], do: [], else: ["--depth", "1"])
  defp quiet(opts), do: if(opts[:quiet], do: ["--quiet"], else: [])

  defp run_git(args) do
    case System.cmd("git", args, stderr_to_stdout: true) do
      {output, 0} ->
        if output != "", do: Mix.shell().info(output)
        :ok

      {output, status} ->
        Mix.raise("git #{Enum.join(args, " ")} failed (#{status}):\n#{output}")
    end
  end
end
