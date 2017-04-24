use Mix.Config

config :blogit,
  repository_url: "git@github.com:meddle0x53/elixir-blog.git",
  polling: true, poll_interval: 60_000,
  posts_folder: ".", assets_path: "assets"
