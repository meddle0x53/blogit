use Mix.Config

config :logger, level: :error

config :blogit,
  repository_url: "/Users/Shared/adata/erlang/elixir/blogit_sample",
  polling: true,
  poll_interval: 5,
  languages: ~w(bg en),
  assets_path: "assets"
