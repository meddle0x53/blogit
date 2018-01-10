defmodule Blogit.Models.Post.MetaTest do
  use ExUnit.Case
  doctest Blogit.Models.Post.Meta

  alias Blogit.Models.Post.Meta

  setup_all do
    Application.ensure_all_started(:yaml_elixir)

    on_exit(fn ->
      Application.stop(:yaml_elixir)
    end)

    Fixtures.posts_in_memory()
  end

  describe ".from_file" do
    test "uses repository data if no meta is found", %{
      repository: %{provider: provider} = repository
    } do
      lang = Blogit.Settings.default_language()
      raw = [nil, ""]
      meta = Meta.from_file("processes.md", repository, raw, "processes", lang)

      assert meta.author == provider.file_info(nil, "processes.md")[:author]

      created_at = to_string(meta.created_at)
      assert created_at == provider.file_info(nil, "processes.md")[:created_at]

      updated_at = to_string(meta.updated_at)
      assert updated_at == provider.file_info(nil, "processes.md")[:updated_at]
    end

    test """
         title is the name of the file with spaces instead of underscores
         and capitalized first letters of every word if no title is specified
         as meta or the content doesn't have title header
         """,
         %{repository: repository} do
      meta =
        Meta.from_file(
          "control_flow_and_errors.md",
          repository,
          [nil, ""],
          "control_flow_and_errors",
          Blogit.Settings.default_language()
        )

      assert meta.title == "Control Flow And Errors"
    end

    test "uses defaults if no meta data can be found", %{repository: repository} do
      lang = Blogit.Settings.default_language()
      raw = [nil, ""]
      meta = Meta.from_file("processes.md", repository, raw, "processes", lang)

      assert meta.tags == []
      assert meta.published == true
      assert meta.category == nil
      assert meta.title_image_path == nil
      assert meta.pinned == false
    end

    test "uses data from the top of the raw content if any", %{repository: repository} do
      raw = """
      ---
      author: valo
      tags:
      - elixir
      - modules
      - functions
      - recursion
      ---

      # Модули, функции и рекурсия

      Организацията на кода в Elixir става чрез модули.
      """

      raw_data =
        String.split(raw, Blogit.Settings.meta_divider(), trim: true)
        |> Enum.map(&String.trim/1)

      meta =
        Meta.from_file(
          "modules_functions_recursion.md",
          repository,
          raw_data,
          "modules_functions_recursion",
          Blogit.Settings.default_language()
        )

      assert meta.author == "valo"
      assert meta.tags == ~w(elixir modules functions recursion)
    end

    test "title is the title header of content if such exists", %{repository: repository} do
      raw = """
      # Модули, функции и рекурсия

      Организацията на кода в Elixir става чрез модули.
      """

      meta =
        Meta.from_file(
          "modules_functions_recursion.md",
          repository,
          [nil, raw],
          "modules_functions_recursion",
          Blogit.Settings.default_language()
        )

      assert meta.title == "Модули, функции и рекурсия"
    end

    test "inline meta overrides file meta", %{repository: repository} do
      raw = """
      ---
      category: Програма
      ---

      # Модули, функции и рекурсия
      """

      raw_data =
        String.split(raw, Blogit.Settings.meta_divider(), trim: true)
        |> Enum.map(&String.trim/1)

      meta =
        Meta.from_file(
          "modules_functions_recursion.md",
          repository,
          raw_data,
          "modules_functions_recursion",
          Blogit.Settings.default_language()
        )

      assert meta.category == "Програма"
    end
  end
end
