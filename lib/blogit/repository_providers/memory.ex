defmodule Blogit.RepositoryProviders.Memory do
  @behaviour Blogit.RepositoryProvider

  defstruct [raw_posts: [], updates: [], files: %{}]

  defmodule RawPost do
    defstruct [
      :author, :path, :meta,
      content: "# Title\n Some text...\n## Section 1\n Hey!!\n* i1\n * i2",
      updated_at: "2017-04-22 13:15:32", created_at: "2017-04-21 22:23:12"
    ]
  end

  ############
  # Specific #
  ############

  def start_link(data \\ %Blogit.RepositoryProviders.Memory{}) do
    Agent.start_link(fn -> data end, name: __MODULE__)
  end

  def stop, do: Agent.stop(__MODULE__)

  def add_file(file_name, data) do
    Agent.get_and_update(__MODULE__,
    fn (%{files: files, updates: updates} = state) ->
      updated = Map.put(files, file_name, data)
      {updated, %{state | files: updated, updates: [file_name | updates]}}
    end)
  end

  def add_post(raw_post) do
    Agent.get_and_update(__MODULE__,
    fn (%{updates: updates, raw_posts: raw_posts} = state) ->
      {state, %{state |
        raw_posts: [raw_post | raw_posts], updates: [raw_post.path | updates]
      }}
    end)
  end

  def delete_post(post_path) do
    Agent.get_and_update(__MODULE__,
    fn (%{updates: updates, raw_posts: raw_posts} = state) ->
      updated_posts = Enum.filter(raw_posts, &(&1.path != post_path))
      {state, %{state |
        raw_posts: updated_posts, updates: [post_path | updates]
      }}
    end)
  end

  def replace_post(raw_post) do
    delete_post(raw_post.path)
    add_post(raw_post)
  end

  #############
  # Behaviour #
  #############

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

  def local_path, do: "memory"
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

  def read_file!(file_name, _) do
    get_post_property_value_by_file_name(:content, file_name)
  end

  def read_file(file_name, _ \\ "") do
    files = Agent.get(__MODULE__, fn (%{files: files}) -> files end)
    case files[file_name] do
      nil -> {:error, :file_not_found}
      data -> {:ok, data}
    end
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
