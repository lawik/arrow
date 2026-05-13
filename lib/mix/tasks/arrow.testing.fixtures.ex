defmodule Mix.Tasks.Arrow.Testing.Fixtures do
  @shortdoc "Clone or update the apache/arrow-testing repo into priv/arrow-testing"

  @moduledoc """
  Pulls the Arrow project's cross-language integration test fixtures.

  Arrow ships a shared repository of test data at
  https://github.com/apache/arrow-testing. The Elixir test suite uses those
  fixtures to verify that this library round-trips data identically to the
  C++, Rust, Java, Go, JS, and Python implementations.

  Running this task clones (or `git pull`s) that repository into
  `priv/arrow-testing/`. Once present, `mix test --include fixtures` exercises
  every JSON integration fixture against `Arrow.Json`.

      mix arrow.testing.fixtures

  The repository is cloned shallowly (`--depth 1`) to keep the download small.
  Pass `--full` to fetch the entire history if you need it for a specific
  reason. Pass `--quiet` to suppress git's progress output.
  """

  use Mix.Task

  @repo "https://github.com/apache/arrow-testing.git"
  @target "priv/arrow-testing"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [full: :boolean, quiet: :boolean])

    cond do
      File.dir?(Path.join(@target, ".git")) ->
        update(opts)

      File.exists?(@target) ->
        Mix.raise("#{@target} exists but is not a git checkout; remove it and re-run")

      true ->
        clone(opts)
    end

    Mix.shell().info("Arrow testing fixtures ready at #{@target}")
  end

  defp clone(opts) do
    File.mkdir_p!("priv")
    Mix.shell().info("Cloning #{@repo} → #{@target}")

    args =
      ["clone"] ++
        if(opts[:full], do: [], else: ["--depth", "1"]) ++
        if(opts[:quiet], do: ["--quiet"], else: []) ++
        [@repo, @target]

    run_git(args)
  end

  defp update(opts) do
    Mix.shell().info("Refreshing #{@target} (git pull --ff-only)")

    args =
      ["-C", @target, "pull", "--ff-only"] ++
        if opts[:quiet], do: ["--quiet"], else: []

    run_git(args)
  end

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
