# Blogit

Blogit is a blog engine back-end written in Elixir. It turns a repository (by default git repository),
containing markdown files into streams of blog posts, which can be queried.
Blogit supports blog configuration in YAML, including blog title, path to custom stiles and images, etc.

There is a front-end implementation in phoenix, which uses Blogit - [BlogitWeb](https://github.com/meddle0x53/blogit_web).
It can be forked and configured to use any repository to build custom blog.

The [blog](https://blog.elixir-lang.bg) for the Sofia University Elixir course runs on Blogit.

## Installation

It is [available in Hex](https://hex.pm/docs/publish), so the package can be installed as:

  1. Add `blogit` to your list of dependencies in `mix.exs`:

      ```elixir
      def deps do
        [{:blogit, "~> 1.0.0"}]
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
  polling: true, poll_interval: 300_000
```

Possible settings are:
* `repository_url`      |> Tells Blogit the location of the repository to use to build its contents.
* `polling`             |> Tells Blogit if it should poll the repository specified through `repository_url` for changes. By default it is `true`.
* `poll_interval`       |> Used if `polling` is set to `true`. The polling for changes will happen on this interval of milliseconds. By default it is `10_000` milliseconds or `10` seconds.
* `repository_provider` |> Specified a specific implementation of the [Blogit.RepositoryProvider](https://github.com/meddle0x53/blogit/blob/master/lib/blogit/repository_provider.ex) behaviour. By default it uses `Blogit.RepositoryProviders.Git` which works with git repositories and knows how to check for changes in them.
* `configuration_file`  |> Path to YAML file in the repository, which contains configuration for the blog. By default it is `blog.yml`.

Using these settings a custom blog can be created from whatever repository. It is not hard to write FTP repository provider or Ecto repository provider.

## Usage

Blogit has a public interface which can be used to build a blog similar to [BlogitWeb](https://github.com/meddle0x53/blogit_web).
When the application is configured and started, the following functions can be called:

  * `Blogit.list_posts(from \\ 0, size \\ 5)`

    Returns a list of `Blogit.Models.Post` structures representing posts in
    the blog. The posts are sorted by their creation date, newest first.

    All the markdown files in the configured `posts_folder` will be transformed
    into `Blogit.Models.Post` structures and their `created_at` meta field
    will be read using the configured `Blogit.RepositoryProvider`.

    Posts can be skipped using the `from` argument, which is `0` by default.
    The size of the returned list is `5` by default, but it can be changed
    with the second argument of the function - `size`.
    By using these two arguments simple paging functionality can be implemented.

  * `Blogit.list_pinned()`

    Returns a list of `Blogit.Models.Post` structures representing pinned
    posts in the blog. These posts are sorted by their last updated date.

    All the markdown files in the configured `posts_folder` will be transformed
    into `Blogit.Models.Post` structures and their `updated_at` meta field
    will be read using the configured `Blogit.RepositoryProvider`.

    Pinned posts are posts which have specified `pinned: true` in their meta
    data.

  * `Blogit.filter_posts(filters, from, size)`

    Returns a list of `Blogit.Models.Post` structures, filtered by given criteria.

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

    The other two arguments of the function can be used for paging.
    Filtered posts can be skipped using the `from` argument,
    which is `0` by default. The size of the returned list is `5` by default,
    but it can be changed with the third argument of the function - `size`.

    Example:

      ```elixir
      filters = %{"q" => "OTP", "author" => "meddle", "tags" => "ab"}
      Blogit.filter_posts(filters)
      ```

  * `Blogit.posts_by_dates()`

    Returns lists of posts grouped by years and then months for every year.
    Can be used for implementing an easy-to-browse view component by years/months.

    The result is list of tuples.
    The first element of a tuple is a year.
    The second is a month number.
    The third is a counter - how many posts are created during the month and the year.

    The tuples are sorted from the newest to the oldest, using the years

  * `Blogit.configuration()`

    Retrieves the blog configuration. The configuration is in the form
    of a `Blogit.Models.Configuration` structure.

    It contains title and sub-title of the blog, path to log or background image (or both),
    path to custom CSS file, etc..

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

Follow these steps to create your own blog:
  1. Fork [BlogitWeb](https://github.com/meddle0x53/blogit_web) project.
  2. Modify its `config/prod.exs` configuration:

      ```elixir
      config :blogit,
        repository_url: "<path-to-a-git-repository-with-your-posts>",
        polling: true, poll_interval: 300_000, mode: :prod,
        assets_path: "assets"
      ```

  3. Deploy it somewhere.

     BlogitWeb depends on `distillery` and has a little bash script in its root,
     called `build_release.sh`. Just run it and it will build a release.
     You can also run it like this : `./build_release.sh --upgrade` in order to
     create updated release. Follow `distillery`'s notes when deploying.'

     BlogitWeb has a `Dockerfile.build` file which can be used to make a build in
     `Docker` if you don't have `Elixir` installed. It has a `Dockerfile` too so
     you can try it locally.
  4. When it is deployed just add new markdown posts to your repository specified
     in the configuration and it will be published automatically.

## Features to be implemented

  * Multiple languages. This way we'll have blogs that have streams
    in multiple languages.
  * Pages (for example 'about me') and specific streams of posts, presented as pages.
  * Slides. If we have a folder containing a specifically formated markdown (?) files, they could be
    turned into slides available on Blogit.
  * Different front-ends for Blogit. Not only BlogtWeb. Also let's keep BlogitWeb up to date, tested and documented. For now it is a bit messy, but usable.
  * Multiple source formats for posts, not only MARKDOWN.
  * Additional repository providers.
  * Social media integrations.

## Contact me

I'm Nikolay Tsvetinov (meddle) from [elixir-lang.bg](https://blog.elixir-lang.bg/posts).

You can find me at:
* [Twitter](https://twitter.com/ntzvetinov)
* [Github](https://github.com/meddle0x53)
* [Gmail](mailto:n.tzvetinov@gmail.com)
* [elixir-lang.bg](mailto:n.tzvetinov@elixir-lang.bg)
