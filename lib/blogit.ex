defmodule Blogit do
  @moduledoc """
  The Blogit Application module for the application :blogit.

  The application is started using this module and can be used using the
  public interface it provides.

  What is Blogit? Blogit is a blog engine. It uses a repository (by default
  a git repository) containing markdown files to build posts and
  configuration for a blog. It can be used by, for example, Phoenix
  application as a backend. An example of such Phoenix application is
  [Blogit Web](https://github.com/meddle0x53/blogit_web).

  An example of a running blog which uses Blogit and Blogit Web is the
  blog of the Elixir Course of the Sofia University :
  [blog.elixir-lang.bg](https://blog.elixir-lang.bg/posts).
  Its repository, used by Blogit can be found here
  https://github.com/ElixirCourse/blog.

  Yes Blogit is the Elixir version of Octopress. That said, Blogit is very
  extensible - the repository it uses can be something other than a Git one.
  For example it could be FTP, local file system, Mnesia, Postgres, etc...
  The only thing needed is to implement the Blogit.RepositoryProvider behaviour
  and to configure Blogit to use it:

  Example (`config/prod.exs`):
  ```elixir
    config :blogit,
      repository_url: "some_protocol://some_location.net",
      repository_provider: Blogit.RepositoryProviders.MyProvider
  ```

  For now the post files have to be in markdown, but this will be configurable
  too. The metadata of a post is in YAML for the moment.

  As Blogit is simple OTP Application with very simple public interface,
  presented by this module, it can have custom front-end too.
  It can be Phoenix+HTLM, Phoenix+React.js, Phoenix+ELM, it can be just
  some Plug application, it can use gen_tcp or be some blog-in-the-terminal.

  So Blogit is blog engine by a programmer for programmers.
  """

  use Application

  alias Blogit.Components.Posts
  alias Blogit.Components.PostsByDate
  alias Blogit.Components.Configuration

  alias Blogit.Models.Post

  alias Blogit.Logic.Search

  @repository_provider Application.get_env(
    :blogit, :repository_provider, Blogit.RepositoryProviders.Git
  )

  def start(_type, _args) do
    Blogit.Supervisor.start_link(@repository_provider)
  end

  @doc """
  Returns a list of Blogit.Models.Post structures representing posts in
  the blog. The posts are sorted by their creation date, newest first.

  All the markdown files in the configured posts folder will be transformed
  into Blogit.Models.Post structures and their `created_at` meta field
  will be read using the configured Blogit.RepositoryProvider.

  Example configuration (`config/prod.exs`):
  ```elixir
    config :blogit,
      repository_url: "some_protocol://some_location.net",
      repository_provider: Blogit.RepositoryProviders.MyProvider,
      posts_folder: "path-to-the-posts-folder-relative-to-the-repository-root"
  ```

  By default this folder is set to "." - the root of the repository.

  Posts can be skipped using the `from` argument, passed to the function,
  which is `0` by default. The size of the returned list is `5` by default,
  but it can be changed with the second argument of the function - `size`.
  By using these two arguments simple paging functionality can be implemented.
  """
  @spec list_posts(non_neg_integer, non_neg_integer) :: [Post.t]
  def list_posts(from \\ 0, size \\ 5) do
    GenServer.call(Posts, {:list, from, size})
  end

  @doc """
  Returns a list of Blogit.Models.Post structures representing pinned
  posts in the blog. These posts are sorted by their last updated date.

  All the markdown files in the configured posts folder will be transformed
  into Blogit.Models.Post structures and their `updated_at` meta field
  will be read using the configured Blogit.RepositoryProvider.

  Pinned posts are posts which have specified `pinned: true` in their meta
  data.

  These are special posts which should be easy to find in the frontend
  implementation.
  """
  @spec list_pinned() :: [Post.t]
  def list_pinned(), do: GenServer.call(Posts, :list_pinned)

  @doc """
  Returns a list of Blogit.Models.Post structures, filtered by given criteria.

  The first argument of the function is a map of filters.
  This map supports zero or more of the following keys:
  * "author" - Used to filter posts by their `.meta.author` field.
  * "category" - Used to filter posts by their `.meta.category` field.
  * "tags" - Used to filter posts by their `.meta.tags` field.
    The value for this key should a string of comma separated tags.
  * "year" - Used to filter posts by their `.meta.year` field.
  * "month" - Used to filter posts by their `.meta.month` field.
  * "q" - A query to filter posts by their content or title. Supports text in
    double quotes in order to search for phrases.

  For more information on the filtering see
  Blogit.Logic.Search.filter_by_params/2.

  The other two arguments of the function can be used for paging.
  Filtered posts can be skipped using the `from` argument,
  which is `0` by default. The size of the returned list is `5` by default,
  but it can be changed with the third argument of the function - `size`.
  """
  @type filters :: %{String.t => Search.search_value}
  @spec filter_posts(filters, non_neg_integer, non_neg_integer) :: [Post.t]
  def filter_posts(params, from \\ 0, size \\ 5) do
    GenServer.call(Posts, {:filter, params, from, size})
  end

  @doc """
  Returns lists of posts grouped by years and then months for every year.

  Can be used for implementing an easy-to-browse view component by years/months.

  For more information see Blogit.Models.Post.collect_by_year_and_month/1.
  """
  @spec posts_by_dates() :: Post.year_month_count_result
  def posts_by_dates, do: GenServer.call(PostsByDate, :get)

  @doc """
  Returns a single post by its unique indentifier - its `name` field.
  The name should be an atom.

  Posts have unique names, usually constructed using the file path of their
  source markdown file in the repository.

  If there is no post with the given name, the atom `:error` is returned.
  """
  @spec post_by_name(atom) :: Post.t | :error
  def post_by_name(name), do: GenServer.call(Posts, {:by_name, name})

  @doc """
  Retrieves the blog configuration. The configuration is in the form
  of a Blogit.Models.Configuration structure.
  """
  @spec configuration :: Blogit.Models.Configuration.t
  def configuration do
    GenServer.call(Configuration, :get)
  end
end
