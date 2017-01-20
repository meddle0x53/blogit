defmodule PostSpec do
  use ESpec
  alias Blogit.Post

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
      path = Path.join("spec/data", "test_with_title.md")
      expect Post.from_file_name("test_with_title.md", nil)
      |> to(eq %Post{
        name: "test_with_title", path: path, raw: File.read!(path),
        html: Earmark.to_html(File.read!(path)),
        updated_at: "2017-01-20 8:35:21 +02:00",
        created_at: "2017-01-20 8:35:21 +02:00", author: "meddle",
        title: "My Special title"
      })
    end

    it "sets the title from name of the file when no title is contained" do
      path = Path.join("spec/data", "test_with_no_title.md")
      expect Post.from_file_name("test_with_no_title.md", nil)
      |> to(eq %Post{
        name: "test_with_no_title", path: path, raw: File.read!(path),
        html: Earmark.to_html(File.read!(path)),
        updated_at: "2017-01-20 8:35:21 +02:00",
        created_at: "2017-01-20 8:35:21 +02:00", author: "meddle",
        title: "Test With No Title"
      })
    end
  end
end
