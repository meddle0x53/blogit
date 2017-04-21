defmodule Blogit.Mixfile do
  use Mix.Project

  def project do
    [app: :blogit,
     version: "0.7.3",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     docs: [readme: true, main: "README.md"],
     description: """
       Blogit is an OTP application for generating blog posts from a git
       repository containing markdown files.
     """,
     package: package(),
     deps: deps()]
  end

  def application do
    [applications: [:logger, :yaml_elixir],
     mod: {Blogit, []}]
  end

  defp deps do
    [
      {:git_cli, "~> 0.2"},
      {:earmark, "~> 1.1"},
      {:yaml_elixir, "~> 1.3.0"},
      {:calendar, "~> 0.16.1"},
      {:ex_doc, ">= 0.15.0", only: :dev}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Nikolay Tsvetinov (Meddle)"],
      links: %{"GitHub" => "https://github.com/meddle0x53/blogit"}
    }
  end
end
