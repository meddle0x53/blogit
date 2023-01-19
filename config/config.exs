import Config

import_config "#{config_env()}.exs"

config :blogit,
  components: [
    Blogit.Components.Configuration,
    Blogit.Components.Posts,
    Blogit.Components.PostsByDate,
    Blogit.Components.Metas
  ]
