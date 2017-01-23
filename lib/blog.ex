defmodule Blogit.Blog do
  alias Blogit.GitRepository

  defstruct [:title, :logo_path, :sub_title]

  @configuration_file Application.get_env(
                        :blogit, :configuration_file, "blog.yml"
                      )

  def from_configuration do
    path = Path.join(GitRepository.local_path, @configuration_file)
    from_path(File.read(path))
  end

  def configuration_updated?(updates) do
    Enum.member?(updates, @configuration_file)
  end

  defp from_path({:error, _}) do
    from_defaults
  end

  defp from_path({:ok, data}) do
    try do
      from_yml(YamlElixir.read_from_string(data))
    rescue
      _ -> from_defaults
    end
  end

  defp from_yml(data) when is_map(data) do
    %__MODULE__{
      title: data["title"] || default_title,
      logo_path: data["logo_path"] || nil,
      sub_title: data["sub_title"] || nil
    }
  end

  defp from_yml(_), do: from_defaults

  defp from_defaults do
    %__MODULE__{ title: default_title, logo_path: nil, sub_title: nil }
  end

  defp default_title do
    GitRepository.local_path
    |> Path.basename
    |> String.split(~r{[^A-Za-z0-9]})
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
