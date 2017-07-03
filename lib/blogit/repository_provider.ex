defmodule Blogit.RepositoryProvider do
  @moduledoc """
  A behaviour module for implementing access to remote or local repository
  with files from which a blog and its posts can be built.

  A provider to a repository should be able to check if files exist in it,
  if files were updated or deleted, to check the author of a file and its
  dates of creation and last update. Also it should provide a way to read
  a file and its meta data.

  A repository provider can be set for the Blogit OTP application using the
  configuration key `:repository_provider`. By default it is
  `Blogit.RepositoryProviders.Git`.

  An example of implementing this behaviour could be a local folder.
  When a new files are added, modified and removed the
  `Blogit.RepositoryProvider.fetch/1` should have in its result the paths of
  these files. The meta data of the file can be used as  meta data
  and creation and last update dates. The author of the file could be its owner.
  The repository structure could contain absolute path to the parent folder
  of the folder representing the repository and the
  `Blogit.RepositoryProvider.local_path/0` could return its name.

  For now `Blogit` comes with two implementations.

  `Blogit.RepositoryProvider.Git` provides access to Git repository and is the
  default provider if none is specified in the configuration.

  `Blogit.RepositoryProvider.Memory` provides access to in-memory repository,
  which can be used (and is used) mainly for testing purposes.
  """

  @type repository :: term
  @type provider :: module
  @type fetch_result :: {:no_updates} | {:updates, [String.t]}
  @type timestamp :: String.t

  @type file_path :: String.t
  @type folder :: String.t
  @type file_read_result :: {:ok, binary} | {:error, File.posix}

  @type t :: %__MODULE__{repo: repository, provider: provider}
  @enforce_keys(:provider)
  defstruct [:repo, :provider]

  @doc """
  Invoked to get representation structure of the repository the provider
  manages.
  This structure can be passed to other callbacks in order to manage files
  in the repository.
  """
  @callback repository() :: repository

  @doc """
  Invoked to get a representation structure of the repository the provider
  manages.
  All the actual data represented by this structure will be updated to its
  newest versions first.

  If, for example the repository is remote, all the files in it should be
  downloaded so their most recent versions are accessible.

  This structure can be passed to other callbacks in order to manage files
  in the repository.
  """
  @callback updated_repository() :: repository

  @doc """
  Invoked to update the data represented by the given `repository` to its most
  recent version.

  If, for example the repository is remote, all the files in it should be
  downloaded so their most recent versions are accessible.
  """
  @callback fetch(repository) :: fetch_result

  @doc """
  Invoked to get the path to the locally downloaded data.
  """
  @callback local_path() :: String.t

  @doc """
  Invoked to get a list of file paths of the files contained in the locally
  downloaded repository.
  """
  @callback local_files() :: [file_path]

  @doc """
  Checks if a file path is contained in the local version of the repository.
  """
  @callback file_in?(file_path) :: boolean

  @doc """
  Invoked to get the author of the file located at the given `file_path`.
  """
  @callback file_author(repository, file_path) :: String.t

  @doc """
  Invoked to get the creation date of the file located at the given
  `file_path`.
  """
  @callback file_created_at(repository, file_path) :: timestamp

  @doc """
  Invoked to get the date of the last update of the file located at the given
  `file_path`.
  """
  @callback file_updated_at(repository, file_path) :: timestamp

  @doc """
  Invoked in order to read the contents of the file located at the given
  `file_path`. If the file could not be read an error is raised.

  The second parameter can be a path to a folder relative to
  `Blogit.RepositoryProvider.local_path/0` in which the given `file_path` should
  exist.
  """
  @callback read_file!(file_path, folder) :: String.t

  @doc """
  Invoked in order to read the contents of the file located at the given
  `file_path`.

  The second parameter can be a path to a folder relative to
  `Blogit.RepositoryProvider.local_path/0` in which the given `file_path` should
  exist.
  """
  @callback read_file(file_path, folder) :: file_read_result

  @doc """
  Invoked in order to read the meta data of the file located at the given
  `file_path`.

  The second parameter can be a path to a folder relative to
  `Blogit.RepositoryProvider.local_path/0` in which the given `file_path` should
  exist.
  """
  @callback read_meta_file(file_path, folder) :: file_read_result
end
