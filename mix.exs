defmodule Blogit.Mixfile do
  use Mix.Project

  def project do
    [app: :blogit,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :timex],
     mod: {Blogit, []}]
  end

  defp deps do
    [
      {:git_cli, "~> 0.2"},
      {:earmark, "~> 1.0.3"},
      {:timex, "~> 3.1.7"}
    ]
  end
end
