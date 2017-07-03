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
  ```

  All of these properties are optional and there are defaults for them.
  For example the default title of the blog is the name of the repository,
  updated a bit.
  """

  @file_conf Application.get_env(:blogit, :configuration_file, "blog.yml")

  @type string_or_nil :: String.t | nil
  @type t :: %__MODULE__{
    title: String.t, sub_title: string_or_nil, logo_path: string_or_nil,
    background_image_path: string_or_nil, styles_path: string_or_nil
  }
  @enforce_keys [:title]
  defstruct [
    :title, :logo_path, :sub_title, :background_image_path, :styles_path
  ]

  @doc """
  Creates a Configuration structure from a file contents.

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
  """
  @spec from_file(Blogit.RepositoryProvider.provider) :: t
  def from_file(repository_provider) do
    from_path(repository_provider.read_file(@file_conf), repository_provider)
  end

  @doc """
  Checks if the name of the configuration file of the blog is in a list
  containing updated file names.

  ## Examples

      iex> Blogit.Models.Configuration.updated?(~w(one.md some_other.md))
      false

      iex> Blogit.Models.Configuration.updated?(~w(one.md blog.yml))
      true
  """
  @spec updated?([String.t]) :: boolean
  def updated?(updates) do
    Enum.member?(updates, @file_conf)
  end

  defp from_path({:error, _}, repository_provider) do
    from_defaults(repository_provider)
  end

  defp from_path({:ok, data}, repository_provider) do
    try do
      from_yml(YamlElixir.read_from_string(data), repository_provider)
    rescue
      _ -> from_defaults(repository_provider)
    end
  end

  defp from_yml(data, repository_provider) when is_map(data) do
    %__MODULE__{
      title: data["title"] || default_title(repository_provider),
      logo_path: data["logo_path"] || nil,
      sub_title: data["sub_title"] || nil,
      background_image_path: data["background_image_path"] || nil,
      styles_path: data["styles_path"] || nil
    }
  end

  defp from_yml(_, repository_provider), do: from_defaults(repository_provider)

  defp from_defaults(repository_provider) do
    %__MODULE__{
      title: default_title(repository_provider), logo_path: nil, sub_title: nil,
      background_image_path: nil
    }
  end

  defp default_title(repository_provider) do
    repository_provider.local_path
    |> Path.basename
    |> String.split(~r{[^A-Za-z0-9]})
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
