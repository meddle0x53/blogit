defmodule Blogit.Mixfile do
  use Mix.Project

  @version "1.2.3"

  def project do
    [
      app: :blogit,
      version: @version,
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: [
        extras: ["README.md"],
        main: "readme",
        source_ref: "v#{@version}",
        source_url: "https://github.com/meddle0x53/blogit"
      ],
      description: """
        Blogit is an OTP application for generating blog posts from a git
        repository containing markdown files.
      """,
      package: package(),
      aliases: aliases(),
      dialyzer: [plt_add_deps: :apps_direct, plt_add_apps: [:yaml_elixir]],
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :yaml_elixir], mod: {Blogit, []}]
  end

  defp deps do
    [
      {:git_cli, "~> 0.3.0"},
      {:earmark, "~> 1.4.34"},
      {:yaml_elixir, "~> 2.9.0"},
      {:calendar, "~> 1.0.0"},
      {:ex_doc, ">= 0.29.1", only: :dev},
      {:dialyxir, "~> 1.2.0", only: [:dev], runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Nikolay Tsvetinov (Meddle)"],
      links: %{"GitHub" => "https://github.com/meddle0x53/blogit"}
    }
  end

  defp aliases do
    [test: "test --no-start"]
  end
end
