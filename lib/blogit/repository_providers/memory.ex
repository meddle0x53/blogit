defmodule Blogit.RepositoryProviders.Memory do
  @moduledoc """
  This module implements the `Blogit.RepositoryProvider` behaviour.

  It provides an in-memory repository access which can be used for testing.

  The repository is just an Agent process, so messages could be sent to it
  in order to make add or remove data to or from it.
  """

  @behaviour Blogit.RepositoryProvider

  alias Blogit.RepositoryProviders.Memory.RawPost
  @opaque t :: %__MODULE__{
    raw_posts: [RawPost.t], updates: [String.t], files: %{String.t => term}
  }
  defstruct [raw_posts: [], updates: [], files: %{}]

  defmodule RawPost do
    @opaque t :: %__MODULE__{
      author: String.t, path: String.t, meta: String.t, content: String.t,
      updated_at: String.t, created_at: String.t
    }
    defstruct [
      :author, :path, :meta,
      content: "# Title\n Some text...\n## Section 1\n Hey!!\n* i1\n * i2",
      updated_at: "2017-04-22 13:15:32", created_at: "2017-04-21 22:23:12"
    ]
  end

  ############
  # Specific #
  ############

  @doc """
  Starts the memory repository as a process. The process is names and
  its name is the name of this module.

  Accepts parameter of type `Blogit.RepositoryProviders.Memory.t`. By default
  the repository is empty.
  """
  @spec start_link(t) :: {:ok, pid} | {:error, term}
  def start_link(data \\ %Blogit.RepositoryProviders.Memory{}) do
    Agent.start_link(fn -> data end, name: __MODULE__)
  end

  @doc """
  Stops the memory repository process.
  """
  @spec stop() :: :ok
  def stop, do: Agent.stop(__MODULE__)

  @doc """
  Adds a file to the in-memory repository using the given file_path as path
  to the file to create and the data as its contents.

  Returns the state of the repository before the modification.
  """
  @spec add_file(String.t, term) :: t
  def add_file(file_path, data) do
    Agent.get_and_update(__MODULE__,
    fn (%{files: files, updates: updates} = state) ->
      updated = Map.put(files, file_path, data)
      {state, %{state | files: updated, updates: [file_path | updates]}}
    end)
  end

  @doc """
  Adds a post to the in-memory repository. Returns the state of the in-memory
  repository before the addition.
  """
  @spec add_post(RawPost.t) :: t
  def add_post(raw_post) do
    Agent.get_and_update(__MODULE__,
    fn (%{updates: updates, raw_posts: raw_posts} = state) ->
      {state, %{state |
        raw_posts: [raw_post | raw_posts], updates: [raw_post.path | updates]
      }}
    end)
  end

  @doc """
  Deletes a post from the in-memory repository. Returns the state of the
  repository before the modification.
  """
  @spec delete_post(String.t) :: t
  def delete_post(post_path) do
    Agent.get_and_update(__MODULE__,
    fn (%{updates: updates, raw_posts: raw_posts} = state) ->
      updated_posts = Enum.filter(raw_posts, &(&1.path != post_path))
      {state, %{state |
        raw_posts: updated_posts, updates: [post_path | updates]
      }}
    end)
  end

  @doc """
  Replaces an existing post from the in-memory repository with new content.
  If the post doesn't exit, creates it. Returns the state of the repository
  before the modification.
  """
  @spec replace_post(RawPost.t) :: t
  def replace_post(raw_post) do
    Agent.get_and_update(__MODULE__,
    fn (%{updates: updates, raw_posts: raw_posts} = state) ->
      updated_posts = Enum.filter(raw_posts, &(&1.path != raw_post.path))
      {state, %{state |
        raw_posts: [raw_post | updated_posts],
        updates: [raw_post.path | updates]
      }}
    end)
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
