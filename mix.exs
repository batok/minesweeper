defmodule Minesweeper.Mixfile do
  use Mix.Project

  def project do
    [
      app: :minesweeper,
      version: "0.1.0",
      elixir: "~> 1.5-dev",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :hackney, :poison, :cowboy, :plug],
      mod: {Minesweeper.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.2.0"},
      {:cowboy, "~> 1.0"},
      {:plug, github: "elixir-lang/plug"},
      {:poison, "~> 2.0"},
      {:credo, github: "rrrene/credo", only: [:dev, :test]}
    ]
  end
end
