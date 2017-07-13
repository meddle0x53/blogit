defmodule Blogit.Settings do

  @configuration_file Application.get_env(
    :blogit, :configuration_file, "blog.yml"
  )
  @posts_folder "posts"

  def languages, do: Application.get_env(:blogit, :languages, ~w(en))

  def default_language, do: languages() |> List.first
  def additional_languages() do
    [_ | rest] = languages()
    rest
  end

  def configuration_file, do: @configuration_file

  def posts_folder, do: @posts_folder
end
