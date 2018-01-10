use Mix.Config

import_config "#{Mix.env()}.exs"

config :blogit,
  components: [
    Blogit.Components.Configuration,
    Blogit.Components.Posts,
    Blogit.Components.PostsByDate,
    Blogit.Components.Metas
  ]
