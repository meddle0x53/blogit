defmodule Blogit.RepositoryProviders.Memory do
  @moduledoc """
  This module implements the `Blogit.RepositoryProvider` behaviour.

  It provides in-memory repository access which can be used for testing.

  The repository is just an `Agent` process, so messages could be sent to it
  in order to add or remove data to or from it.
  """

  @behaviour Blogit.RepositoryProvider

  alias Blogit.Settings
  alias Blogit.RepositoryProviders.Memory.File

  @opaque t :: %__MODULE__{
            stored_files: [File.t()],
            updates: [String.t()],
            files: %{String.t() => term}
          }
  defstruct stored_files: [], updates: [], files: %{}

  defmodule File do
    @moduledoc false

    @opaque t :: %__MODULE__{
              author: String.t(),
              path: String.t(),
              content: String.t(),
              updated_at: String.t(),
              created_at: String.t()
            }
    defstruct [
      :author,
      :path,
      content: "# Title\n Some text...\n## Section 1\n Hey!!\n* i1\n * i2",
      updated_at: "2017-04-22 13:15:32",
      created_at: "2017-04-21 22:23:12"
    ]
  end

  #######
  # API #
  #######

  @doc """
  Starts the memory repository as a process. The process is named and
  its name is the name of this module.

  Accepts argument of type `Blogit.RepositoryProviders.Memory.t`. By default
  the repository is empty.
  """
  @spec start_link(t) :: {:ok, pid} | {:error, term}
  def start_link(data \\ %Blogit.RepositoryProviders.Memory{}) do
    Agent.start_link(fn -> data end, name: __MODULE__)
  end

  @doc """
  Stops the in-memory repository process.
  """
  @spec stop() :: :ok
  def stop, do: Agent.stop(__MODULE__)

  @doc """
  Adds a file to the in-memory repository using the given `file_path` as path
  to the file to create and the given `data` as its contents.

  Returns the state of the repository before the modification.
  """
  @spec add_file(String.t(), term) :: t
  def add_file(file_path, data) do
    Agent.get_and_update(__MODULE__, fn %{files: files, updates: updates} = state ->
      updated = Map.put(files, file_path, data)
      {state, %{state | files: updated, updates: [file_path | updates]}}
    end)
  end

  @doc """
  Stores a file in the in-memory repository. Returns the state of the in-memory
  repository before the addition.
  """
  @spec add_file(File.t()) :: t
  def add_file(file) do
    Agent.get_and_update(__MODULE__, fn %{updates: updates, stored_files: stored_files} = state ->
      final_updates = [
        Path.join(Settings.posts_folder(), file.path) | updates
      ]

      {state, %{state | stored_files: [file | stored_files], updates: final_updates}}
    end)
  end

  @doc """
  Deletes a file from the in-memory repository. Returns the state of the
  repository before the modification.
  """
  @spec delete_file(String.t()) :: t
  def delete_file(file_path) do
    Agent.get_and_update(__MODULE__, fn %{updates: updates, stored_files: stored_files} = state ->
      updated = Enum.filter(stored_files, &(&1.path != file_path))
      final_updates = [Path.join(Settings.posts_folder(), file_path) | updates]

      {state, %{state | stored_files: updated, updates: final_updates}}
    end)
  end

  @doc """
  Replaces an existing file's content with new content.
  If the file doesn't exist, creates it. Returns the state of the repository
  before the modification.
  """
  @spec replace_file(File.t()) :: t
  def replace_file(file) do
    Agent.get_and_update(__MODULE__, fn %{updates: updates, stored_files: stored_files} = state ->
      updated = Enum.filter(stored_files, &(&1.path != file.path))

      final_updates = [
        Path.join(Settings.posts_folder(), file.path) | updates
      ]

      {state, %{state | stored_files: [file | updated], updates: final_updates}}
    end)
  end

  #############
  # Callbacks #
  #############

  def repository, do: __MODULE__

  def fetch(_) do
    Agent.get_and_update(__MODULE__, fn data ->
      case Enum.empty?(data.updates) do
        true -> {{:no_updates}, data}
        false -> {{:updates, data.updates}, %{data | updates: []}}
      end
    end)
  end

  def local_path, do: "memory"

  def list_files(_ \\ "") do
    Agent.get(__MODULE__, fn %{stored_files: files} ->
      files |> Enum.map(fn file -> file.path end)
    end)
  end

  def file_in?(file) do
    Agent.get(__MODULE__, fn %{stored_files: files} ->
      files |> find_by_file_name(file)
    end)
  end

  def file_info(_, file_name) do
    %{
      author: file_author(file_name),
      created_at: file_created_at(file_name),
      updated_at: file_updated_at(file_name)
    }
  end

  def read_file(file_name, folder \\ "") do
    if folder == Settings.posts_folder() do
      case get_file_property_value_by_file_name(:content, file_name) do
        nil -> {:error, :file_not_found}
        data -> {:ok, data}
      end
    else
      files = Agent.get(__MODULE__, fn %{files: files} -> files end)

      case files[file_name] do
        nil -> {:error, :file_not_found}
        data -> {:ok, data}
      end
    end
  end

  ###########
  # Private #
  ###########

  defp get_file_property_value_by_file_name(property, file_name) do
    Agent.get(__MODULE__, fn %{stored_files: files} ->
      case files |> find_by_file_name(file_name) do
        nil -> nil
        file -> Map.get(file, property)
      end
    end)
  end

  defp find_by_file_name(files, file_name) do
    root = "#{Settings.posts_folder()}/"

    files
    |> Enum.find(fn file ->
      file.path == file_name |> String.replace_leading(root, "")
    end)
  end

  defp file_author(file_name) do
    get_file_property_value_by_file_name(:author, file_name)
  end

  defp file_created_at(file_name) do
    get_file_property_value_by_file_name(:created_at, file_name)
  end

  defp file_updated_at(file_name) do
    get_file_property_value_by_file_name(:updated_at, file_name)
  end
end
