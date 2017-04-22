defmodule Blogit.Models.PostTest do
  use ExUnit.Case
  doctest Blogit.Models.Post

  alias Blogit.Models.Post
  alias Blogit.Models.Post.Meta

  alias Blogit.RepositoryProviders.Memory
  alias Blogit.RepositoryProviders.Memory.RawPost
  alias Blogit.RepositoryProvider, as: Repository

  setup do
    raw_posts = [
      %RawPost{author: "meddle", path: "processes.md", content: "Stuff"},
      %RawPost{author: "valo", path: "modules_functions_recursion.md"},
      %RawPost{author: "Reductions", path: "mix.md"},
      %RawPost{author: "Andreshk", path: "control_flow_and_errors.md"}
    ]

    Memory.start_link(%Memory{raw_posts: raw_posts})

    %{repository: %Repository{provider: Memory}}
  end

  describe ".from_file" do
    setup %{repository: repository} = context do
      post = Post.from_file("processes.md", repository)
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

    test "stores the meta-data retrieved as 'meta'", %{post: post} do
      assert post.meta == %Meta{
        author: "meddle", title: "Processes", tags: [],
        pinned: false, published: true,
        created_at: ~N[2017-04-21 22:23:12],
        updated_at: ~N[2017-04-22 13:15:32]
      }
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

      assert posts == %{
        mix: %Post{
          name: "mix",
          html: mix_html,
          raw: "# Title\n Some text...\n## Section 1\n Hey!!\n* i1\n * i2",
          meta: %Meta{
            author: "Reductions",
            category: nil, created_at: ~N[2017-04-21 22:23:12],
            pinned: false, published: true, tags: [], title: "Title",
            title_image_path: nil, updated_at: ~N[2017-04-22 13:15:32]
          }
        },
        processes: %Post{
          name: "processes",
          html: "<p>Stuff</p>\n",
          raw: "Stuff",
          meta: %Meta{
            author: "meddle", category: nil,
            created_at: ~N[2017-04-21 22:23:12], pinned: false,
            published: true, tags: [], title: "Processes",
            title_image_path: nil, updated_at: ~N[2017-04-22 13:15:32]
          }
        }
      }
    end
  end
end
