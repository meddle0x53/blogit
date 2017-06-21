use Mix.Config

config :blogit,
       repository_url: "spec/data", polling: false, posts_folder: "posts",
       repository_provider: Blogit.RepositoryProviders.Memory
