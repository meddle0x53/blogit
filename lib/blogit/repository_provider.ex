defmodule Blogit.RepositoryProvider do
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

  @callback repository() :: repository
  @callback updated_repository() :: repository
  @callback fetch(repository) :: fetch_result

  @callback local_path() :: String.t
  @callback local_files() :: [file_path]
  @callback file_in?(file_path) :: boolean

  @callback file_author(repository, file_path) :: String.t
  @callback file_created_at(repository, file_path) :: timestamp
  @callback file_updated_at(repository, file_path) :: timestamp

  @callback read_file!(file_path, folder) :: String.t
  @callback read_file(file_path, folder) :: file_read_result
  @callback read_meta_file(file_path, folder) :: file_read_result
end
