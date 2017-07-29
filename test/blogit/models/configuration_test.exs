defmodule Blogit.Models.ConfigurationTest do
  use ExUnit.Case
  doctest Blogit.Models.Configuration

  alias Blogit.Models.Configuration

  setup_all do: Application.put_env(:blogit, :configuration_file, "blog.yml")

  setup do: Fixtures.setup()

  describe ".from_file" do
    test "returns a default configuration if file can't be found",
    %{repository: repository} do
      configuration = Configuration.from_file(repository.provider)

      assert configuration == Blogit.Settings.languages() |> Enum.map(fn lang ->
        %Configuration{title: "Memory", language: lang}
      end)
    end

    test "returns a default configuration if the file is invalid YML file",
    %{repository: repository} do
      repository.provider.add_file("blog.yml", "<><>Junk<><>")
      configuration = Configuration.from_file(repository.provider)

      assert configuration == %Configuration{title: "Memory"}
    end

    test "returns a configuration from file, if it is valid YML",
    %{repository: repository} do
      yml = """
      title: Test Blog
      sub_title: Testing it now
      logo_path: some/image.jpg
      styles_path: some/styles.css
      background_image_path: some/other_image.jpg
      """
      repository.provider.add_file("blog.yml", yml)

      configuration = Configuration.from_file(repository.provider)
      assert List.first(configuration) == %Configuration{
        title: "Test Blog", sub_title: "Testing it now",
        logo_path: "some/image.jpg", styles_path: "some/styles.css",
        background_image_path: "some/other_image.jpg",
        language: ~s[bg]
      }
    end

    test """
    returns a configuration from file, if it is valid YML and uses the
    defaults for missing properties
    """, %{repository: repository} do
      yml = ~S"""
      sub_title: "Testing it now"
      logo_path: some/image.jpg
      styles_path: some/styles.css
      """
      repository.provider.add_file("blog.yml", yml)

      configuration = Configuration.from_file(repository.provider)
      assert List.first(configuration) == %Configuration{
        title: "Memory", sub_title: "Testing it now",
        logo_path: "some/image.jpg", styles_path: "some/styles.css",
      }
    end

    test "TODO", %{repository: repository} do
      current_languages = Blogit.Settings.languages()
      Application.put_env(:blogit, :languages, ~w(en bg de))

      yml = """
      title: Test blog
      sub_title: Testing it with languages
      logo_path: some/image.jpg
      styles_path: some/styles.css
      background_image_path: some/other_image.jpg
      bg:
        title: Тестов блог
        sub_title: С езици
        logo_path: some/bg_image.jpg
      de:
       title: Das ist mein blog
       sub_title: Ich spreche Deuch
      """

      repository.provider.add_file("blog.yml", yml)

      configuration = Configuration.from_file(repository.provider)
      en = %Configuration{
        title: "Test blog", sub_title: "Testing it with languages",
        logo_path: "some/image.jpg", styles_path: "some/styles.css",
        background_image_path: "some/other_image.jpg", language: "en"
      }

      bg = %Configuration{
        title: "Тестов блог", sub_title: "С езици",
        logo_path: "some/bg_image.jpg", styles_path: "some/styles.css",
        background_image_path: "some/other_image.jpg", language: "bg"
      }

      de = %Configuration{
        title: "Das ist mein blog", sub_title: "Ich spreche Deuch",
        logo_path: "some/image.jpg", styles_path: "some/styles.css",
        background_image_path: "some/other_image.jpg", language: "de"
      }

      assert configuration == [en, bg, de]

      Application.put_env(:blogit, :languages, current_languages)
    end
  end
end
