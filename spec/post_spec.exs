defmodule PostSpec do
  use ESpec
  alias Blogit.Post
  alias Blogit.Meta

  let :repository, do: %Git.Repository{path: "data"}

  describe "from_file_name" do
    it "sets the title from the title of the markdown" do
      path = Path.join("data/posts", "test_with_title.md")
      expect Post.from_file_name("test_with_title.md", repository())
      |> to(eq %Post{
        name: "test_with_title", path: path, raw: File.read!(path),
        html: Earmark.to_html(File.read!(path)),
        meta: %Meta{
          updated_at: ~N[2017-01-23 13:17:35],
          created_at: ~N[2017-01-23 13:17:35], author: "meddle",
          title: "My Special title", category: nil, tags: [], published: true
        }
      })
    end

    it "sets the title from name of the file when no title is contained" do
      path = Path.join("data/posts", "test_with_no_title.md")
      expect Post.from_file_name("test_with_no_title.md", repository())
      |> to(eq %Post{
        name: "test_with_no_title", path: path, raw: File.read!(path),
        html: Earmark.to_html(File.read!(path)),
        meta: %Meta{
          updated_at: ~N[2017-01-23 13:17:35],
          created_at: ~N[2017-01-23 13:17:35], author: "meddle",
          title: "Test With No Title", category: nil, tags: [], published: true
        }
      })
    end

    it "sets data from a meta YML file if it exists " do
      path = Path.join("data/posts", "test_with_meta.md")
      html = File.read!(path)

      expect Post.from_file_name("test_with_meta.md", repository())
      |> to(eq %Post{
        name: "test_with_meta", path: path, raw: File.read!(path),
        html: Earmark.to_html(String.replace(html, ~r/^\s*\#\s*.+/, "")),
        meta: %Meta{
          updated_at: ~N[2016-03-03 23:21:11],
          created_at: ~N[2015-03-03 23:21:11], author: "Elixir",
          title: "Custom Title", published: false, category: "dummy",
          tags: ~w(lame test stuff), title_image_path: "some.jpg"
        }
      })
    end

    it "sets data from inline meta block if it exists " do
      path = Path.join("data/posts", "test_with_inline_meta.md")
      html = File.read!(path)
             |> String.split("<><><><><><><><>", trim: true)
             |> List.last
             |> String.replace(~r/^\s*\#\s*.+/, "")
             |> Earmark.to_html

      expect Post.from_file_name("test_with_inline_meta.md", repository())
      |> to(eq %Post{
        name: "test_with_inline_meta", path: path, raw: File.read!(path),
        html: html, meta: %Meta{
          updated_at: ~N[2017-02-02 15:05:15],
          created_at: ~N[2017-02-02 15:05:15], author: "Whiterun",
          title: "This title should be extracted as title of the post",
          published: false, category: "games",
          tags: [], title_image_path: "mine.jpg"
        }
      })
    end
  end

  describe "compile_posts" do
    before do
      allow(Post).to accept(:from_file_name, fn (name, _) ->
        %Post{name: name, path: name, raw: nil, html: nil, meta: nil}
      end)
    end

    it "compiles only *.md files in a map with keys the names of the posts" do
      files = ~w(post1.md post2.md some.txt other.json post3.md)

      expect Post.compile_posts(files, nil)
      |> to(eq %{
        "post1.md": %Blogit.Post{
          html: nil, meta: nil, name: "post1.md", path: "post1.md", raw: nil
        },
        "post2.md": %Blogit.Post{
          html: nil, meta: nil, name: "post2.md", path: "post2.md", raw: nil
        },
        "post3.md": %Blogit.Post{
          html: nil, meta: nil, name: "post3.md", path: "post3.md", raw: nil
        }
      })
    end
  end

  describe "collect_by_year_and_month" do
    it "returns a map containing easy accesible posts by year and month" do
      posts = (1..7)
      |> Enum.map(fn number -> "post#{number}.md" end)
      |> Enum.map(fn file -> Post.from_file_name(file, repository()) end)

      expect Post.collect_by_year_and_month(posts)
      |> to(eq %{
        2015 => %{
          3 => [posts |> Enum.at(2), posts |> Enum.at(0)]
        },
        2016 => %{
          5 => [posts |> Enum.at(1)]
        },
        2017 => %{
          1 => [posts |> Enum.at(6), posts |> Enum.at(3)],
          2 => [posts |> Enum.at(5), posts |> Enum.at(4)]
        }
      })
    end
  end
end
