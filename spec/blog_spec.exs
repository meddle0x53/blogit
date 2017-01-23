defmodule BlogSpec do
  use ESpec
  alias Blogit.Blog

  describe "from_configuration" do
    before do
      allow(Blogit.GitRepository).to accept(:local_path, fn -> "spec/data" end)
    end

    it "creates the structure with defaults if configuration does not exist" do
      expect Blog.from_configuration
      |> to(eq %Blog{
        title: "Data", logo_path: nil, sub_title: nil
      })
    end

    it "creates the structure with defaults if the configuration is broken" do
      allow(Path).to accept(:join, fn("spec/data", "blog.yml") ->
            "spec/data/broken_configuration.yml"
      end)

      expect Blog.from_configuration
      |> to(eq %Blog{
        title: "Data", logo_path: nil, sub_title: nil
      })
    end

    it "uses the configuration if the the configuration file is valid" do
      allow(Path).to accept(:join, fn("spec/data", "blog.yml") ->
            "spec/data/some.yml"
      end)

      expect Blog.from_configuration
      |> to(eq %Blog{
        title: "My Blog", logo_path: nil, sub_title: "Tadaaa"
      })
    end
  end
end
