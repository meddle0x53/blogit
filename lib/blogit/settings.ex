defmodule Blogit.Settings do
  @moduledoc """
  Provides application-wide settings for `Blogit`.

  All of the functions in this modules are settings, which can be reused
  through the other modules.
  """

  @configuration_file Application.get_env(
    :blogit, :configuration_file, "blog.yml"
  )
  @posts_folder "posts"
  @meta_divider "\n---\n"
  @max_lines_in_preview Application.get_env(:blogit, :max_lines_in_preview, 10)

  @doc """
  Retrieves the list of supported languages configured for `Blogit`.

  The languages can be configured like this:
  ```
  config :blogit,
         repository_url: some-url, repository_provider: some-provider,
         languages: ~w(bg en)
  ```

  For every configured language a separate set of posts and blog configuration
  is kept. Every language has its own `Blogit.Components.*` processes running,
  that can be queried.

  By default the list of languages is `["en"]`.

  ## Examples

      iex> Application.put_env(:blogit, :languages, ["es"])
      iex> Blogit.Settings.languages()
      ["es"]

      iex> Application.delete_env(:blogit, :languages) # Use default
      iex> Blogit.Settings.languages()
      ["en"]
  """
  @spec languages() :: [String.t]
  def languages, do: Application.get_env(:blogit, :languages, ~w(en))

  @doc """
  Returns the default language configured for `Blogit`. This is the first
  language in the list of languages configured like this:
  ```
  config :blogit,
         repository_url: some-url, repository_provider: some-provider,
         languages: ~w(bg en)
  ```

  By default it is `"en"` for English.

  ## Examples

      iex> Application.put_env(:blogit, :languages, ["es", "bg", "de"])
      iex> Blogit.Settings.default_language()
      "es"

      iex> Application.delete_env(:blogit, :languages) # Use default
      iex> Blogit.Settings.default_language()
      "en"
  """
  @spec default_language() :: String.t
  def default_language, do: languages() |> List.first

  @doc """
  Returns a list of the additional or secondary languages configured for
  `Bogit`. These are all the language without the first one from `:languages`
  configuration like this one:
  ```
  config :blogit,
         repository_url: some-url, repository_provider: some-provider,
         languages: ~w(bg en)
  ```

  By default it is an empty list.

  ## Examples

      iex> Application.put_env(:blogit, :languages, ["es", "bg", "de"])
      iex> Blogit.Settings.additional_languages()
      ["bg", "de"]

      iex> Application.delete_env(:blogit, :languages) # Use default
      iex> Blogit.Settings.additional_languages()
      []
  """
  @spec additional_languages() :: [String.t]
  def additional_languages do
    [_ | rest] = languages()
    rest
  end

  def configuration_file, do: @configuration_file

  def posts_folder, do: @posts_folder

  def meta_divider, do: @meta_divider

  def max_lines_in_preview, do: @max_lines_in_preview
end
