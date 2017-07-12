defmodule Blogit.Settings do

  @configuration_file Application.get_env(
    :blogit, :configuration_file, "blog.yml"
  )

  def languages, do: Application.get_env(:blogit, :languages, ~w(en))

  def default_language, do: languages() |> List.first

  def configuration_file, do: @configuration_file
end
