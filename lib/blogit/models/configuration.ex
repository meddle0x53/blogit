defmodule Blogit.Models.Configuration do
  defstruct [
    :title, :logo_path, :sub_title, :background_image_path, :styles_path
  ]

  @configuration_file Application.get_env(
                        :blogit, :configuration_file, "blog.yml"
                      )

  def from_file(repository_provider) do
    path = Path.join(repository_provider.local_path, @configuration_file)
    from_path(File.read(path), repository_provider)
  end

  def updated?(updates) do
    Enum.member?(updates, @configuration_file)
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
