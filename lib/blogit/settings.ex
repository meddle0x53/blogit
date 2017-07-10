defmodule Blogit.Settings do

  @default_language Application.get_env(:blogit, :default_language, "en")
  @configuration_file Application.get_env(
    :blogit, :configuration_file, "blog.yml"
  )

  def default_language, do: @default_language
  def configuration_file, do: @configuration_file
end
