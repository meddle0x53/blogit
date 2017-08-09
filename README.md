# Blogit

Blogit is a blog engine back-end written in Elixir.
It turns a repository (by default git repository),
containing markdown files into streams of blog posts, which can be queried.
Blogit supports blog configuration in YAML, including blog title, path to custom styles and images, etc.

There is a front-end implementation in Phoenix, which uses Blogit - [BlogitWeb](https://github.com/meddle0x53/blogit_web).
It can be forked and configured to use any repository to build custom blog.

The [blog](https://blog.elixir-lang.bg) for the Sofia University Elixir course runs on Blogit.

## Installation

It is [available in Hex](https://hex.pm/docs/publish), so the package can be installed:

  1. Add `blogit` to your list of dependencies in `mix.exs`:

      ```elixir
      def deps do
        [{:blogit, "~> 1.1.0"}]
      end
      ```

  2. Ensure `blogit` is started before your application:

      ```elixir
      def application do
        [applications: [:blogit]]
      end
      ```

## Configuration

An example configuration for blogit is:

```elixir
config :blogit,
  repository_url: "https://github.com/ElixirCourse/blog.git",
  polling: true, poll_interval: 300, languages: ~w(en bg de)
```

Possible settings are:
* `repository_url`       |> Tells Blogit the location of the repository to use to build its contents.
* `polling`              |> Tells Blogit if it should poll the repository specified through `repository_url` for changes. By default it is `true`.
* `poll_interval`        |> Used if `polling` is set to `true`. The polling for changes will happen on this interval of seconds. By default it is `10` seconds.
* `repository_provider`  |> Specified a specific implementation of the [Blogit.RepositoryProvider](https://github.com/meddle0x53/blogit/blob/master/lib/blogit/repository_provider.ex) behaviour. By default it uses `Blogit.RepositoryProviders.Git` which works with git repositories and knows how to check for changes in them.
* `configuration_file`   |> Path to YAML file in the repository, which contains configuration for the blog. By default it is `blog.yml`.
* `languages`            |> A list of language codes. By default it is `["en"]`. The first language of the list is the default and primaty language. If there are alternative languages, if post source files are created in the folder `<repo-root>/posts/<lang-code>`, the posts compiled from them are marked that are in the given language. They can be queried with `Blogit.list_posts(language: "<lang-code>")`.
* `max_lines_in_preview` |> The maximum lines to be used from the content of the original post source to generate its preview. The preview is generated from the beginning of the content and contains maximum `max_lines_in_preview` lines. By default this value is `10`.

Using these settings a custom blog can be created from whatever repository. It is not hard to write FTP repository provider or Ecto repository provider.

## Usage

Blogit has a public interface which can be used to build a blog similar to [BlogitWeb](https://github.com/meddle0x53/blogit_web).
When the application is configured and started, the following functions can be called:

  * `Blogit.list_posts(options)`

    Returns a list of `Blogit.Models.Post.Meta` structs representing posts previews in
    the blog. The posts are sorted by their creation date, newest first.

    All the markdown files in the folder `<repo-root>/posts` will be transformed
    into `Blogit.Models.Post` structs and their `created_at` meta field
    will be read using the configured `Blogit.RepositoryProvider`.

    Post previews can be skipped using the `from` option, which is `0` by default.
    The size of the returned list is `:infinity` by default (meaning "return all post previews"), but it can be changed
    with the `size` option to a number.
    By using these two options simple paging functionality can be implemented.

    Another supported option is `language`. It defaults to the default language (the first one in the configured `languages` list).
    A stream of post previews for the given `language` will be returned.

    Examples:

      ```elixir
      # All post previews in the default language
      post_previews = Blogit.list_posts()

      # The first 5 post previews in the default language
      post_previews = Blogit.list_posts(size: 5)

      # The second 5 post previews in the default language
      post_previews = Blogit.list_posts(size: 5, from: 5)

      # All post previews in Bulgarian
      post_previews = Blogit.list_posts(language: "bg")

      # The second 5 post previews in Bulgarian
      post_previews = Blogit.list_posts(language: "bg", size: 5, from: 5)
      ```

  * `Blogit.list_pinned(options)`

    Returns a list of tuples. Every such tuple has the unique name of a post as first
    element and its title as second. These tuples are sorted by the
    last updated date of the posts they represent.

    All the markdown files in the source `posts` folder will be transformed
    into `Blogit.Models.Post` strucs and their `updated_at` meta field
    will be read using the configured `Blogit.RepositoryProvider`.

    Pinned posts are posts which have specified `pinned: true` in their meta
    data.

    These are special posts which should be easy to find in the front-end
    implementation.

    The only supported option is `language`.
    It defaults to the default language (the first one in the configured `languages` list).
    Pinned post tuples for the given `language` will be returned.

    Examples:

      ```elixir
      # Pinned post tuples for the default language
      Blogit.list_pinned()

      # Pinned post tuples for posts in German
      Blogit.list_pinned(language: "de")
      ```

  * `Blogit.filter_posts(filters, options)`

    Returns a list of `Blogit.Models.Post.Meta` structs, filtered by the given `filters`.

    The first argument of the function is a map of filters.
    This map supports zero or more of the following keys:
    * "author" - Used to filter posts by their `.meta.author` field.
    * "category" - Used to filter posts by their `.meta.category` field.
    * "tags" - Used to filter posts by their `.meta.tags` field.
      The value for this key should a string of comma separated tags (`"one,two,three"`).
    * "year" - Used to filter posts by their `.meta.year` field.
    * "month" - Used to filter posts by their `.meta.month` field.
    * "q" - A query to filter posts by their content or title. Supports text in
      double quotes in order to search for phrases.

    All these keys must be strings.

    Filtered post previews can be skipped using the `from` option, which is `0` by default.
    The size of the returned list is `:infinity` by default (meaning "return all filtered post previews"), but it can be changed
    with the `size` option to a number.
    By using these two options simple paging functionality can be implemented.

    Another supported option is `language`.
    It defaults to the default language (the first one in the configured `languages` list).
    A stream of post previews, filtered by the given `filters` for the given `language` will be returned.

    Examples:

      ```elixir
      # All the post previews in the default language, filtered by the given `filters`
      filters = %{"q" => "OTP", "author" => "meddle", "tags" => "ab"}
      Blogit.filter_posts(filters)

      # The second two post previews in German, filtered by the given `filters`
      filters = %{"q" => "OTP", "author" => "meddle", "tags" => "ab"}
      Blogit.filter_posts(filters, language: "de", from: 2, size: 2)
      ```

  * `Blogit.posts_by_dates(options)`

    Returns a list of tuples of three elements from the given list of posts.

    The first element of a tuple is a year.
    The second is a month number.
    The third is a counter - how many posts are created during that month
    and that year.

    The tuples are sorted from the newest to the oldest, using the years and the months.

    Can be used for implementing an easy-to-browse view component by years/months.

    The only supported option is `language`.
    It defaults to the default language (the first one in the configured `languages` list).
    Statistics for the posts in the given `language` will be returned.

    Examples:

      ```elixir
      # Statistics for the posts in the default language
      posts_by_date = Blogit.posts_by_dates()
      # [{2017, 6, 5}, {2017, 5, 1}, {2016, 5, 1}]

      # Statistics for the posts in Bulgarian
      posts_by_date = Blogit.posts_by_dates(language: "bg")
      # [{2017, 5, 1}, {2016, 5, 1}]
      ```

  * `Blogit.post_by_name(name, options)`

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

    Examples:

      ```elixir
      # A post with the name `:otp`, written in the default language
      {:ok, post} = Blogit.post_by_name(:otp)
      IO.puts post.name # :otp
      IO.puts post.meta.author # The author of the post
      IO.puts post.raw # The source markdown of the post

      # A post with the name `:otp`, written in Bulgarian
      {:ok, post} = Blogit.post_by_name(:otp, language: "bg")
      ```

  * `Blogit.configuration(options)`

    Retrieves the blog configuration. The configuration is in the form
    of a `Blogit.Models.Configuration` struct.

    It contains title and sub-title of the blog, path to logo or background image (or both),
    path to custom CSS file, etc..

    The configuration is generated from an YAML file (by default blog.yml, stored
    in the root of the repository of the blog). This location can be configured
    through setting the `:configuration_file` key of the `:blogit` configuration.

    The only supported option is `language`.
    It defaults to the default language (the first one in the configured `languages` list).
    Configuration for the given `language` will be returned.

    Examples:

      ```elixir
      # The configuration of the blog for the default language
      Blogit.configuration()

      # The configuration for the German part of the blog
      Blogit.configuration(language: "de")
      ```

## License

The license is standard MIT license, feel free to fork Blogit and do whatever
you want with it. You can also contribute to it.

## Contributions

Just fork the Blogit repository and create a PR. You can also create issues
with features you wish we support. You can propose style changes on the code and
additional tests.

All kinds of contributions are welcome!

## How to create your own blog?

Blogit has a simple Phoenix front-end application : [BlogitWeb](https://github.com/meddle0x53/blogit_web).

Follow these steps to create your own blog (read more at [BlogitWeb's README](https://github.com/meddle0x53/blogit_web/blob/master/README.md)):
  1. Fork [BlogitWeb](https://github.com/meddle0x53/blogit_web) project.
  2. Modify its `config/prod.exs` configuration:

      ```elixir
      config :blogit,
        repository_url: "<path-to-a-git-repository-with-your-posts>",
        polling: true, poll_interval: 300
      ```

  3. Recompile the dependencies, so the configuration is updated:

      ```bash
      mix deps.get
      mix deps.clean
      mix deps.compile
      ```

  4. Deploy it somewhere.

     BlogitWeb depends on `distillery` and has a little bash script in its root,
     called `build_release.sh`. Just run it and it will build a release.
     You can also run it like this : `./build_release.sh --upgrade` in order to
     create updated release. Follow `distillery`'s notes when deploying.'

     BlogitWeb has a `Dockerfile.build` file which can be used to make a build in
     `Docker` if you don't have `Elixir` installed. It has a `Dockerfile` too so
     you can try it locally.

     There is a template `edeliver` configuration too.

  5. When it is deployed just add new markdown posts to your repository specified
     in the configuration and it will be published automatically.

## Features to be implemented

  * Pages (for example 'about me') and specific streams of posts, presented as pages.
  * Slides. If we have a folder containing a specifically formated markdown (?) files, they could be
    turned into slides available on Blogit.
  * Different front-ends for Blogit. Not only BlogtWeb. Also let's keep BlogitWeb up to date, tested and documented. For now it is a bit messy, but usable.
  * Multiple source formats for posts, not only MARKDOWN.
  * Additional repository providers.

## Contact me

I'm Nikolay Tsvetinov (meddle) from [elixir-lang.bg](https://blog.elixir-lang.bg/posts).

You can find me at:
* [Twitter](https://twitter.com/ntzvetinov)
* [Github](https://github.com/meddle0x53)
* [Gmail](mailto:n.tzvetinov@gmail.com)
* [elixir-lang.bg](mailto:n.tzvetinov@elixir-lang.bg)
* [My blog, implemented using Blogit](http://themeddle.com)
