defmodule Blogit.Settings do
  @moduledoc """
  Provides application-wide settings for `Blogit`.

  All of the functions in this modules are settings, which can be reused
  through the other modules.
  """

  @posts_folder "posts"
  @meta_divider "\n---\n"

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

      iex> Application.put_env(:blogit, :languages, ["bg"])
      iex> Blogit.Settings.languages()
      ["bg"]

      iex> Application.delete_env(:blogit, :languages) # Use default
      iex> Blogit.Settings.languages()
      ["en"]
  """
  @spec languages() :: [String.t()]
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

      iex> Application.put_env(:blogit, :languages, ["bg", "de"])
      iex> Blogit.Settings.default_language()
      "bg"

      iex> Application.delete_env(:blogit, :languages) # Use default
      iex> Blogit.Settings.default_language()
      "en"
  """
  @spec default_language() :: String.t()
  def default_language, do: languages() |> List.first()

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
  @spec additional_languages() :: [String.t()]
  def additional_languages do
    [_ | rest] = languages()
    rest
  end

  @doc """
  Returns the path to the configuration file of `Blogit`. It can be configured
  like this:
  ```
  config :blogit,
         repository_url: some-url, repository_provider: some-provider,
         configuration_file: path-to-the-file.yml
  ```

  By default it is in the root of the repository and called 'blog.yml'.

  ## Examples

      iex> Application.put_env(:blogit, :configuration_file, "my_conf.yml")
      iex> Blogit.Settings.configuration_file()
      "my_conf.yml"

      iex> Application.delete_env(:blogit, :configuration_file) # Use default
      iex> Blogit.Settings.configuration_file()
      "blog.yml"
  """
  @spec configuration_file() :: String.t()
  def configuration_file do
    Application.get_env(:blogit, :configuration_file, "blog.yml")
  end

  @doc """
  Returns the string `"posts"` - the location of the posts folder in the
  repository. A custom provider can opt to not use this default location, but
  the `Blogit.RepositoryProviders.Git` provider expects posts to be located
  in a folder named `posts` in the root of the repository.

  ## Examples

      iex> Blogit.Settings.posts_folder()
      "posts"
  """
  @spec posts_folder() :: String.t()
  def posts_folder, do: @posts_folder

  @doc ~S"""
  Returns the string `"\n---\n"` - the divider used to separate the meta data
  from the post content in the post markdown files. It's advisable to have it on
  two places - before and after the metadata:

  ```
  ---
  author: Dali
  ---

  # My meta content
  ```

  ## Examples

      iex> Blogit.Settings.meta_divider()
      "\n---\n"
  """
  @spec meta_divider() :: String.t()
  def meta_divider, do: @meta_divider

  @doc """
  Returns how many lines of the source file of a post should be used for
  generating its preview. Can be configured in the `Blogit` configuration:

  ```
  config :blogit,
         repository_url: some-url, repository_provider: some-provider,
         max_lines_in_preview: 30
  ```

  If not configured its default value is `10`.

  ## Examples

      iex> Application.put_env(:blogit, :max_lines_in_preview, 30)
      iex> Blogit.Settings.max_lines_in_preview()
      30

      iex> Application.delete_env(:blogit, :max_lines_in_preview) # Use default
      iex> Blogit.Settings.max_lines_in_preview()
      10
  """
  @spec max_lines_in_preview() :: pos_integer
  def max_lines_in_preview do
    Application.get_env(:blogit, :max_lines_in_preview, 10)
  end

  @doc """
  Returns true if polling the source repository for changes is configured to be
  'on'. That can be done like this:
  ```
  config :blogit,
         repository_url: some-url, repository_provider: some-provider,
         polling: true
  ```

  The default is `true` if it is not configured.

  ## Examples

      iex> Application.put_env(:blogit, :polling, true)
      iex> Blogit.Settings.polling?()
      true

      iex> Application.put_env(:blogit, :polling, false)
      iex> Blogit.Settings.polling?()
      false

      iex> Application.delete_env(:blogit, :polling) # Use default
      iex> Blogit.Settings.polling?()
      true
  """
  @spec polling?() :: boolean
  def polling?, do: Application.get_env(:blogit, :polling, true)

  @doc """
  Returns the interval used when polling the source repository for changes.
  It is used only if `Blogit.Settings.polling?()` returns `true`.
  The value is the interval in milliseconds. The configuration is specified
  in seconds, like this:
  ```
  config :blogit,
         repository_url: some-url, repository_provider: some-provider,
         polling: true, poll_interval: 50
  ```

  The default is `10_000` for ten seconds.

  ## Examples

      iex> Application.put_env(:blogit, :poll_interval, 60)
      iex> Blogit.Settings.poll_interval()
      60_000

      iex> Application.delete_env(:blogit, :poll_interval) # Use default
      iex> Blogit.Settings.poll_interval()
      10_000
  """
  @spec poll_interval() :: pos_integer
  def poll_interval, do: Application.get_env(:blogit, :poll_interval, 10) * 1000
end
