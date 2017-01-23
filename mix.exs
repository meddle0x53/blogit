defmodule Blogit.Mixfile do
  use Mix.Project

  def project do
    [app: :blogit,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     preferred_cli_env: [espec: :test],
     deps: deps()]
  end

  def application do
    [applications: [:logger, :yaml_elixir],
     mod: {Blogit, []}]
  end

  defp deps do
    [
      {:git_cli, "~> 0.2"},
      {:earmark, "~> 1.0.3"},
      {:yaml_elixir, "~> 1.3.0"},
      {:espec, "~> 1.2.1", only: :test}
    ]
  end
end
