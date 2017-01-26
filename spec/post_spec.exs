defmodule PostSpec do
  use ESpec
  alias Blogit.Post
  alias Blogit.Meta

  describe "from_file_name" do
    before do
      allow(Blogit.GitRepository).to accept(:local_path, fn -> "spec/data" end)
      allow(Blogit.GitRepository).to accept(:file_created_at, fn (_, _) ->
        "2017-01-20 8:35:21 +02:00"
      end)
      allow(Blogit.GitRepository).to accept(:file_updated_at, fn (_, _) ->
        "2017-01-20 8:35:21 +02:00"
      end)
      allow(Blogit.GitRepository).to accept(:file_author, fn (_, _) ->
        "meddle"
      end)
    end

    it "sets the title from the title of the markdown" do
      path = Path.join("spec/data/posts", "test_with_title.md")
      expect Post.from_file_name("test_with_title.md", nil)
      |> to(eq %Post{
        name: "test_with_title", path: path, raw: File.read!(path),
        html: Earmark.to_html(File.read!(path)),
        meta: %Meta{
          updated_at: "2017-01-20 8:35:21 +02:00",
          created_at: "2017-01-20 8:35:21 +02:00", author: "meddle",
          title: "My Special title", category: nil, tags: [], published: true
        }
      })
    end

    it "sets the title from name of the file when no title is contained" do
      path = Path.join("spec/data/posts", "test_with_no_title.md")
      expect Post.from_file_name("test_with_no_title.md", nil)
      |> to(eq %Post{
        name: "test_with_no_title", path: path, raw: File.read!(path),
        html: Earmark.to_html(File.read!(path)),
        meta: %Meta{
          updated_at: "2017-01-20 8:35:21 +02:00",
          created_at: "2017-01-20 8:35:21 +02:00", author: "meddle",
          title: "Test With No Title", category: nil, tags: [], published: true
        }
      })
    end

    it "sets data from a meta YML file if it exists " do
      path = Path.join("spec/data/posts", "test_with_meta.md")
      html = File.read!(path)

      expect Post.from_file_name("test_with_meta.md", nil)
      |> to(eq %Post{
        name: "test_with_meta", path: path, raw: File.read!(path),
        html: Earmark.to_html(String.replace(html, ~r/^\s*\#\s*.+/, "")),
        meta: %Meta{
          updated_at: "2016-03-03 23:21:11 +02:00",
          created_at: "2015-03-03 23:21:11 +02:00", author: "Elixir",
          title: "Custom Title", published: false, category: "dummy",
          tags: ~w(lame test stuff)
        }
      })
    end

    it "sets data from inline meta block if it exists " do
      path = Path.join("spec/data/posts", "test_with_inline_meta.md")
      html = File.read!(path)
             |> String.split("<><><><><><><><>", trim: true)
             |> List.last
             |> String.replace(~r/^\s*\#\s*.+/, "")
             |> Earmark.to_html

      expect Post.from_file_name("test_with_inline_meta.md", nil)
      |> to(eq %Post{
        name: "test_with_inline_meta", path: path, raw: File.read!(path),
        html: html, meta: %Meta{
          updated_at: "2017-01-20 8:35:21 +02:00",
          created_at: "2017-01-20 8:35:21 +02:00", author: "Whiterun",
          title: "This title should be extracted as title of the post",
          published: false, category: "games",
          tags: []
        }
      })
    end
  end
end
