defmodule Blogit do
  @moduledoc """
  The Blogit Application module for the application `:blogit`.

  The application is started using this module and can be used through the
  public interface it provides.

  What is Blogit? Blogit is a blog engine. It uses a repository (by default
  a git repository) containing markdown files to build posts and
  configuration for a blog. It can be used by, for example, Phoenix
  application as a back-end. One such Phoenix application is
  [Blogit Web](https://github.com/meddle0x53/blogit_web).

  An example of a running blog which uses `Blogit` and `Blogit Web` is the
  blog of the Elixir Course of the Sofia University :
  [blog.elixir-lang.bg](https://blog.elixir-lang.bg/posts).
  Its git repository, can be found here https://github.com/ElixirCourse/blog.

  Yes, Blogit is the Elixir version of Octopress. That said, Blogit is very
  extensible - the repository it uses can be something other than a Git one.
  For example it could be FTP, local file system, Mnesia, Postgres, etc...
  The only thing needed is to implement the `Blogit.RepositoryProvider`
  behaviour and to configure Blogit to use it:

  Example (`config/prod.exs`):
  ```elixir
    config :blogit,
      repository_url: "some_protocol://some_location.net",
      repository_provider: Blogit.RepositoryProviders.MyProvider
  ```

  For now the post files have to be in markdown, but this will be configurable
  too. The meta-data of a post is in YAML which could be included in the
  markdown source file of the post, in the beginning.

  As Blogit is simple OTP Application with very simple public interface,
  presented by this module, it can have custom front-end too.
  It can be Phoenix+HTLM, Phoenix+React.js, Phoenix+ELM, it can be just
  some Plug application, it can use `:gen_tcp` or be some blog-in-the-terminal.

  So Blogit is blog engine by a programmer for programmers.
  """

  use Application

  alias Blogit.Components.Posts
  alias Blogit.Components.Metas
  alias Blogit.Components.PostsByDate
  alias Blogit.Components.Configuration

  alias Blogit.Models.Post

  alias Blogit.Logic.Search

  import Blogit.Settings

  @repository_provider Application.get_env(
    :blogit, :repository_provider, Blogit.RepositoryProviders.Git
  )

  @default_from_posts 0
  @default_size_posts :infinity

  def start(_type, _args) do
    Blogit.Supervisor.start_link(@repository_provider)
  end

  @doc """
  Returns a list of `Blogit.Models.Post.Meta` structs representing posts in
  the blog. The posts are sorted by their creation date, newest first.

  All the markdown files in the posts folder will be transformed
  into `Blogit.Models.Post` structs and their `created_at` meta field
  will be read using the configured `Blogit.RepositoryProvider`. The 'meta'
  fields of every post include a `preview` field. Its value is HTML preview
  of the post. The provider implementation should search (by default) for
  posts in a `posts` folder, which should be located at the root of the git
  repository.

  Example configuration (`config/prod.exs`):
  ```elixir
    config :blogit,
      repository_url: "some_protocol://some_location.net",
      repository_provider: Blogit.RepositoryProviders.MyProvider,
      languages: ["en", "bg"]
  ```

  ## Options
  * `:from` (non-negative integer) - all the posts for the given/default
  `language` ordered by their creation date and with indexes smaller than the
  value of this option will be skipped and not present in the result list of
  post meta data. Can be used along with the `:size` option to implement simple
  paging. Defaults to `0`.
  * `:size` (positive integer or `:infinity`) - the maximum number of post meta
  structs in the result. By default it is `:infinity`.
  Can be used along with the `:from` option to implement simple paging.
  * `:language` - different sets of posts can exist for every language
  configured. This option can be used to specify which of these sets should be
  used as the source of the post meta data to be returned.
  By default posts of the default language will be returned.

  ## Example
  ```
  posts = Blogit.list_posts(from: 5, size: 10, language: "es")
  ```
  """
  @spec list_posts(keyword) :: [Post.Meta.t]
  def list_posts(options \\ []) do
    {from, size, language} = read_options(options)
    GenServer.call(Metas.name(language), {:list, from, size})
  end

  @doc """
  Returns a list of tuples. Every such tuple has the unique name of a post as first
  element and its title as second. These tuples are sorted by the
  last updated date of the posts they represent.

  All the markdown files in the source posts folder will be transformed
  into `Blogit.Models.Post` structs and their `updated_at` meta field
  will be read using the configured `Blogit.RepositoryProvider`.

  Pinned posts are posts which have specified `pinned: true` in their meta
  data.

  These are special posts which should be easy to find in the front-end
  implementation.

  The only supported option is `language`.
  It defaults to the default language (the first one in the configured `languages` list).
  Pinned post tuples for the given `language` will be returned.
  """
  @spec list_pinned(keyword) :: [{String.t, String.t}]
  def list_pinned(options \\ []) do
    name = Metas.name(options[:language] || default_language())
    GenServer.call(name, :list_pinned)
  end

  @doc """
  Returns a list of `Blogit.Models.Post.Meta` structs, filtered by given criteria.

  The first argument of the function is a map of filters.
  This map supports zero or more of the following key-values:
  * "author" - Used to filter posts by their `.meta.author` field.
  * "category" - Used to filter posts by their `.meta.category` field.
  * "tags" - Used to filter posts by their `.meta.tags` field.
    The value for this key should a string of comma separated tags.
  * "year" - Used to filter posts by their `.meta.year` field.
  * "month" - Used to filter posts by their `.meta.month` field.
  * "q" - A query to filter posts by their content or title. Supports text in
    double quotes in order to search for phrases.

  For more information on the filtering see
  `Blogit.Logic.Search.filter_by_params/2`.

  ## Options
  * `:from` (non-negative integer) - all the posts meeting the given filtering
  criteria for the given/default `language` ordered by their creation date
  and with indexes smaller than the value of this option will be skipped and
  not present in the result list of posts list. Defaults to `0`.
  Can be used along with the `:size` option to implement simple paging.
  * `:size` (positive integer or `:infinity`) - the maximum number of posts in
  the result. By default it is `:infinity`. Can be used along with the
  `:from` option to implement simple paging.
  * `:language` - different sets of posts can exist for every language
  configured. This option can be used to specify which of these sets should be
  used as the source of the posts to be returned.
  By default posts of the default language will be returned.
  """
  @type filters :: %{String.t => Search.search_value}
  @spec filter_posts(filters, keyword) :: [Post.t]
  def filter_posts(params, options \\ []) do
    {from, size, language} = read_options(options)
    GenServer.call(Posts.name(language), {:filter, params, from, size})
  end

  @doc """
  Returns a list of tuples of three elements from the given list of posts.

  The first element of a tuple is a year.
  The second is a month number.
  The third is a counter - how many posts are created during that month
  and that year.

  Can be used for implementing an easy-to-browse view component by years/months.

  The only supported option is `language`.
  It defaults to the default language (the first one in the configured `languages` list).
  Statistics for the posts in the given `language` will be returned.

  For more information see `Blogit.Models.Post.collect_by_year_and_month/1`.
  """
  @spec posts_by_dates(keyword) :: Post.year_month_count_result
  def posts_by_dates(options \\ []) do
    id = PostsByDate.name(options[:language] || default_language())
    GenServer.call(id, :get)
  end

  @doc """
  Returns a single post by its unique identifier - its `name` field.
  The name should be an atom. The result is in the form `{:ok, post}` if a
  post with the given `name` exist for the given (or default) language.
  The `post` element of that tuple is a `Blogit.Models.Post` struct.

  Posts have unique names, usually constructed using the file path of their
  source markdown file in the repository.

  If there is no post with the given `name`,
  the tuple `{:error, "No post with name the-passed-name found."}` is returned.

  The only supported option is `language`.
  It defaults to the default language (the first one in the configured `languages` list).
  Post with the given `name` in the given `language` will be returned if found.
  """
  @spec post_by_name(atom, keyword) :: {:ok, Post.t} | {:error, String.t}
  def post_by_name(name, options \\ []) do
    {_, _, language} = read_options(options)
    GenServer.call(Posts.name(language), {:by_name, name})
  end

  @doc """
  Retrieves the blog configuration. The configuration is in the form
  of a `Blogit.Models.Configuration` struct.

  The configuration is generated from an YML file (by default blog.yml, stored
  in the root of the repository of the blog). This location can be configured
  through setting the `:configuration_file` key of the `:blogit` configuration.

  The only supported option is `language`.
  It defaults to the default language (the first one in the configured `languages` list).
  Configuration for the given `language` will be returned.
  """
  @spec configuration(keyword) :: Blogit.Models.Configuration.t
  def configuration(options \\ []) do
    name = Configuration.name(options[:language] || default_language())
    GenServer.call(name, :get)
  end

  ###########
  # Private #
  ###########

  defp read_options(options) do
    from = Keyword.get(options, :from, @default_from_posts)
    size = Keyword.get(options, :size, @default_size_posts)
    language = Keyword.get(options, :language, default_language())

    {from, size, language}
  end
end
