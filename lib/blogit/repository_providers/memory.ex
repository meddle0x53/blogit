defmodule Blogit.RepositoryProviders.Memory do
  @behaviour Blogit.RepositoryProvider

  defstruct [raw_posts: [], updates: []]

  defmodule RawPost do
    defstruct [
      :author, :path, :meta,
      content: "# Title\n Some text...\n## Section 1\n Hey!!\n* i1\n * i2",
      updated_at: "2017-04-22 13:15:32", created_at: "2017-04-21 22:23:12"
    ]
  end

  def start_link(data \\ %Blogit.RepositoryProviders.Memory{}) do
    Agent.start_link(fn -> data end, name: __MODULE__)
  end

  def stop, do: Agent.stop(__MODULE__)

  def repository, do: __MODULE__
  def updated_repository, do: __MODULE__

  def fetch(_) do
    Agent.get_and_update(__MODULE__, fn (data) ->
      case Enum.empty?(data.updates) do
        true -> {{:no_updates}, data}
        false -> {{:updates, data.updates}, %{data | updates: []}}
      end
    end)
  end

  def local_path, do: ""
  def local_files do
    Agent.get(__MODULE__, fn (%{raw_posts: posts}) ->
      posts |> Enum.map(fn (post) -> post.path end)
    end)
  end

  def file_in?(file) do
    Agent.get(__MODULE__, fn (%{raw_posts: posts}) ->
      posts |> find_by_file_name(file)
    end)
  end

  def file_author(_, file_name) do
    get_post_property_value_by_file_name(:author, file_name)
  end

  def file_created_at(_, file_name) do
    get_post_property_value_by_file_name(:created_at, file_name)
  end

  def file_updated_at(_, file_name) do
    get_post_property_value_by_file_name(:updated_at, file_name)
  end

  def read_file(file_name, _) do
    get_post_property_value_by_file_name(:content, file_name)
  end

  def read_meta_file(file_name, _) do
    case get_post_property_value_by_file_name(:meta, file_name) do
      nil -> {:error, "Nothing."}
      meta -> {:ok, meta}
    end
  end

  ###########
  # Private #
  ###########

  defp get_post_property_value_by_file_name(property, file_name) do
    Agent.get(__MODULE__, fn (%{raw_posts: posts}) ->
      case posts |> find_by_file_name(file_name) do
        nil -> nil
        post -> Map.get(post, property)
      end
    end)
  end

  defp find_by_file_name(posts, file_name) do
    posts |> Enum.find(fn (post) -> post.path == Path.basename(file_name) end)
  end
end
