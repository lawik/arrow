defmodule Arrow.MixProject do
  use Mix.Project

  def project do
    [
      app: :arrow,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Arrow",
      description: "Pure-Elixir implementation of the Apache Arrow columnar format.",
      docs: docs(),
      package: package(),
      aliases: aliases(),
      dialyzer: dialyzer()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end

  def package do
    [
      name: :arrow,
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/TODO/arrow"}
    ]
  end

  def aliases do
    [
      # `compile --warnings-as-errors` is intentionally relaxed: the FlatBuffers
      # codegen under lib/org/apache/arrow/flatbuf/ currently emits unused
      # alias / unused variable warnings. Tighten back when flatbuf cleans up.
      check: [
        "hex.audit",
        "compile --force",
        "format --check-formatted",
        "credo",
        "deps.unlock --check-unused",
        "spellweaver.check",
        "dialyzer"
      ],
      precommit: [
        "hex.audit",
        "compile --force",
        "format",
        "credo",
        "deps.unlock --unused",
        "spellweaver.check",
        "dialyzer",
        "test"
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  def dialyzer do
    [
      plt_add_apps: [:mix],
      ignore_warnings: ".dialyzer_ignore.exs"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nstandard, "~> 0.3"},
      {:jason, "~> 1.4"},
      {:flatbuf, path: "../flatbuf-stable", only: [:dev], runtime: false},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:ex_doc, "~> 0.40", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:spellweaver, "~> 0.1", only: [:dev, :test], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
