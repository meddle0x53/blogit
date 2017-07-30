defmodule Blogit.Models.PostTest do
  use ExUnit.Case
  doctest Blogit.Models.Post

  alias Blogit.Models.Post
  alias Blogit.Models.Post.Meta

  setup do: Fixtures.setup()

  describe ".from_file" do
    setup %{repository: repository} = context do
      lang = Blogit.Settings.default_language()
      post = Post.from_file("processes.md", repository, lang)
      Map.put(context, :post, post)
    end

    test "uses the file name for name of the post", %{post: post} do
      assert post.name == "processes"
    end

    test "keeps the original source markdown as 'raw'", %{post: post} do
      assert post.raw == "Stuff"
    end

    test "stores the parsed HTML data as 'html'", %{post: post} do
      assert post.html == "<p>Stuff</p>\n"
    end

    test "stores the meta data retrieved as 'meta'", %{post: post} do
      assert post.meta == %Meta{
        author: "meddle", title: "Processes", tags: [],
        pinned: false, published: true, name: "processes",
        created_at: ~N[2017-06-21 08:46:50],
        updated_at: ~N[2017-04-22 13:15:32],
        year: "2017", month: "6", language: "bg", preview: "<p>Stuff</p>\n"
      }
    end

    test "if the source file contains meta data, it is removed from the " <>
    "html of the post and used for the meta", %{repository: repository} do
      lang = Blogit.Settings.default_language()
      post = Post.from_file("nodes.md", repository, lang)

      assert post.html == """
      <p> Some text…</p>\n<h2>Section 1</h2>\n<p> Hey!!</p>\n<ul>\n<li>i1
      </li>\n<li>i2\n</li>\n</ul>
      """

      assert post.meta == %Meta{
        author: "meddle", title: "Title", tags: [],
        pinned: true, published: true, name: "nodes",
        category: "Some",
        created_at: ~N[2017-06-10 18:52:49],
        updated_at: ~N[2017-06-10 18:52:49],
        year: "2017", month: "6", language: "bg",
        preview: "<p> Some text…</p>\n<h2>Section 1</h2>\n<p> Hey!!</p>\n" <>
        "<ul>\n<li>i1\n</li>\n<li>i2\n</li>\n</ul>\n"
      }
    end

    test "if the file located at the given `file_path` is not in the " <>
    "repository, returns :source_file_not_found", %{repository: repository} do
      lang = Blogit.Settings.default_language()
      result = Post.from_file("djasdhasjk.md", repository, lang)

      assert result == :source_file_not_found
    end
   test "if the meta data of the post to be created has `published: false` " <>
    "`post.html` will be `nil`", %{repository: repository} do
      lang = Blogit.Settings.default_language()
      post = Post.from_file("pro_nodes.md", repository, lang)

      assert is_nil(post.html)
      refute post.meta.published
    end
  end

  describe ".compile_posts" do
    test """
    successfully creates a map with keys the names of the posts as atoms
    and values the parsed posts from the given repository at the given
    locations
    """, %{repository: repository} do
      posts = Post.compile_posts(~w(mix.md processes.md), repository)

      mix_html = """
      <p> Some text…</p>\n<h2>Section 1</h2>\n<p> Hey!!</p>\n<ul>\n<li>i1
      </li>\n<li>i2\n</li>\n</ul>
      """

      expected = %{
        Blogit.Settings.default_language() => %{
          mix: %Post{
            name: "mix",
            html: mix_html,
            raw: "# Title\n Some text...\n## Section 1\n Hey!!\n* i1\n * i2",
            meta: %Meta{
              author: "Reductions", name: "mix",
              category: nil, created_at: ~N[2017-05-30 21:26:49],
              pinned: false, published: true, tags: [], title: "Title",
              title_image_path: nil, updated_at: ~N[2017-04-22 13:15:32],
              year: "2017", month: "5", language: "bg", preview: mix_html
            }
          },
          processes: %Post{
            name: "processes",
            html: "<p>Stuff</p>\n",
            raw: "Stuff",
            meta: %Meta{
              author: "meddle", category: nil,
              created_at: ~N[2017-06-21 08:46:50], pinned: false,
              published: true, tags: [], title: "Processes",
              title_image_path: nil, updated_at: ~N[2017-04-22 13:15:32],
              year: "2017", month: "6", language: "bg",
              preview: "<p>Stuff</p>\n", name: "processes"
            }
          }
        }
      }

      expected = Blogit.Settings.additional_languages()
      |> Enum.reduce(expected, fn language, current ->
        Map.put(current, language, %{})
      end)
      assert posts == expected
    end
  end
end
