use Mix.Config

config :blogit,
       repository_url: "spec/data", polling: false, posts_folder: "posts",
       configuration_file: "blog.yml", assets_path: "assets"
