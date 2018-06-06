defmodule Blogit.Models.Configuration do
  @moduledoc """
  A module for managing and reading the blog configuration.

  A repository containing the blog data can also contain an 'yml' configuration
  file. The file should be in the form
  ```
  title: <title>
  sub_title: <a-sub-title-for-the-blog>
  logo_path: <path to logo for the blog>
  background_image_path: <path to image at the top of the feed as background>
  styles_path: <path to css file with custom styles for the blog>
  social:
    rss: <show-rss-feed>(true/false)
    stars_for_blogit: <show-give-stars-for-blogit-links>(true/false)
    twitter: <twitter-id>
    facebook: <facebook-id>
    gihub: <github-id>
  ```

  All of these properties are optional and there are defaults for them.
  For example the default title of the blog is the transformed name of the
  repository (name: 'my_repo' |> title: 'My Repo').

  For every language code, returned by `Blogit.Settings.languages/0` the
  file can have sub-section with custom settings. The configurations for
  the additional languages extend on the configuration of the default language.

  ```
  title: <title>
  sub_title: <a-sub-title-for-the-blog>
  logo_path: <path to logo for the blog>
  background_image_path: <path to image at the top of the feed as background>
  styles_path: <path to css file with custom styles for the blog>
  social:
    rss: <show-rss-feed>(true/false)
    stars_for_blogit: <show-give-stars-for-blogit-links>(true/false)
    twitter: <twitter-id>
    facebook: <facebook-id>
    gihub: <github-id>
  bg:
    title: <title-in-bulgarian>
  ```

  If the default language is `en` for English in the above example,
  the configuration for the Bulgarian language (`bg`) will be the same as the
  English one, but will another title, the one specified under `bg`. All the
  other supported keys can have custom values under `bg`.
  """

  import Blogit.Settings

  @type string_or_nil :: String.t() | nil
  @type t :: %__MODULE__{
          title: String.t(),
          sub_title: string_or_nil,
          logo_path: string_or_nil,
          background_image_path: string_or_nil,
          styles_path: string_or_nil,
          language: String.t(),
          social: %{String.t() => String.t() | boolean}
        }
  @enforce_keys [:title]
  defstruct [
    :title,
    :logo_path,
    :sub_title,
    :background_image_path,
    :styles_path,
    language: default_language(),
    social: %{"rss" => true, "stars_for_blogit" => true}
  ]

  @doc """
  Creates a list of `Blogit.Post.Configuration` struct from the
  configuration source file contents. The list includes configuration for
  every configured language. The first item of the list is the configuration
  for the default language
  (The one returned by invoking `Blogit.Settings.default_language/0`).

  The name and the location of the file are read from the configuration of
  `Blogit` - the configuration property `configuration_file`.

  If the file doesn't exist or it is invalid YML file, the structure is
  created using the defaults.

  The defaults are:
  * title - the name of the repository of the blog.
  * sub_title - nil
  * local_path - nil
  * background_image_path - nil
  * styles_path - nil
  * social: `%{"rss" => true, "stars_for_blogit" => true}`
  * language: <the-language-of-this-configuration> : for every language
              returned by `Blogit.Settings.languages/0` a configuration struct
              will be created and returned by this function.
  """
  @spec from_file(Blogit.RepositoryProvider.provider()) :: [t]
  def from_file(repository_provider) do
    from_path(
      repository_provider.read_file(configuration_file()),
      repository_provider
    )
  end

  @doc """
  Checks if the name of the configuration file of the blog is in the given list
  containing updated file names.

  ## Examples

      iex> Blogit.Models.Configuration.updated?(~w(one.md some_other.md))
      false

      iex> Blogit.Models.Configuration.updated?(~w(one.md blog.yml))
      true
  """
  @spec updated?([String.t()]) :: boolean
  def updated?(updates) do
    Enum.member?(updates, configuration_file())
  end

  ###########
  # Private #
  ###########

  defp from_path({:error, _}, repository_provider) do
    default_result(from_defaults(repository_provider))
  end

  defp from_path({:ok, data}, repository_provider) do
    defaults = from_defaults(repository_provider)

    case YamlElixir.read_from_string(data) do
      {:ok, conf} ->
        from_yml(conf, defaults)
      _ ->
        default_result(defaults)
    end
  end

  defp from_yml(data, template) when is_map(data) do
    main = from_map(data, template)

    additional =
      additional_languages() |> Enum.map(&from_map(data[&1] || %{}, %{main | language: &1}))

    [main | additional]
  end

  defp from_yml(_, template) do
    additional =
      additional_languages()
      |> Enum.map(&from_map(%{}, %{template | language: &1}))

    [template | additional]
  end

  defp from_map(data, template) when is_map(data) do
    %__MODULE__{
      title: data["title"] || template.title,
      logo_path: data["logo_path"] || template.logo_path,
      sub_title: data["sub_title"] || template.sub_title,
      background_image_path: data["background_image_path"] || template.background_image_path,
      styles_path: data["styles_path"] || template.styles_path,
      language: data["language"] || template.language,
      social: data["social"] || template.social
    }
  end

  defp from_defaults(repository_provider) do
    %__MODULE__{
      title: default_title(repository_provider),
      logo_path: nil,
      sub_title: nil,
      background_image_path: nil,
      styles_path: nil,
      language: default_language(),
      social: %{"rss" => true, "stars_for_blogit" => true}
    }
  end

  defp default_title(repository_provider) do
    repository_provider.local_path
    |> Path.basename()
    |> String.split(~r{[^A-Za-z0-9]})
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp default_result(defaults) do
    languages()
    |> Enum.map(fn language ->
      Map.put(defaults, :language, language)
    end)
  end
end
