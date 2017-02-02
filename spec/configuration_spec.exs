defmodule ConfigurationSpec do
  use ESpec
  alias Blogit.Configuration

  describe "from_file" do
    it "creates the structure with defaults if configuration does not exist" do
      expect Configuration.from_file
      |> to(eq %Configuration{
        title: "Data", logo_path: nil, sub_title: nil
      })
    end

    it "creates the structure with defaults if the configuration is broken" do
      allow(Path).to accept(:join, fn("data", "blog.yml") ->
            "data/broken_configuration.yml"
      end)

      expect Configuration.from_file
      |> to(eq %Configuration{
        title: "Data", logo_path: nil, sub_title: nil
      })
    end

    it "uses the configuration if the the configuration file is valid" do
      allow(Path).to accept(:join, fn("data", "blog.yml") ->
        "data/some.yml"
      end)

      expect Configuration.from_file
      |> to(eq %Configuration{
        title: "My Blog", logo_path: nil, sub_title: "Tadaaa"
      })
    end
  end
end
