defmodule Blogit.Models.Post.MetaTest do
  use ExUnit.Case
  doctest Blogit.Models.Post.Meta

  alias Blogit.Models.Post.Meta

  setup do
    Application.ensure_all_started(:yaml_elixir)

    on_exit fn ->
      Application.stop(:yaml_elixir)
    end

    Fixtures.posts_in_memory()
  end

  describe ".from_file" do
    test "uses repository data if no meta is found",
    %{repository: %{provider: provider} = repository} do
      meta = Meta.from_file("processes.md", repository, "", "processes")

      assert meta.author == provider.file_author(nil, "processes.md")

      created_at = to_string(meta.created_at)
      assert created_at == provider.file_created_at(nil, "processes.md")

      updated_at = to_string(meta.updated_at)
      assert updated_at == provider.file_updated_at(nil, "processes.md")
    end

    test """
    title is the name of the file with spaces instead of underscores
    and capitalized first letters of every word if no title is specified
    as meta or the content doesn't have title header
    """, %{repository: repository} do
      meta = Meta.from_file(
      "control_flow_and_errors.md", repository, "", "control_flow_and_errors"
      )

      assert meta.title == "Control Flow And Errors"
    end

    test "uses defaults if no meta data can be found",
    %{repository: repository} do
      meta = Meta.from_file("processes.md", repository, "", "processes")

      assert meta.tags == []
      assert meta.published == true
      assert meta.category == nil
      assert meta.title_image_path == nil
      assert meta.pinned == false
    end

    test "uses data from a meta file if it has any",
    %{repository: repository} do
      meta = Meta.from_file(
        "modules_functions_recursion.md", repository,
        "", "modules_functions_recursion"
      )

      assert meta.pinned == true
      assert meta.category == "Program"
      assert meta.published == false
    end

    test "uses data from the top of the raw content if any",
    %{repository: repository} do
      raw = """
      author: valo
      tags:
      - elixir
      - modules
      - functions
      - recursion

      <><><><><><><><>

      # Модули, функции и рекурсия

      Организацията на кода в Elixir става чрез модули.
      """
      meta = Meta.from_file(
        "modules_functions_recursion.md", repository,
        raw, "modules_functions_recursion"
      )

      assert meta.author == "valo"
      assert meta.tags == ~w(elixir modules functions recursion)
    end

    test "title is the title header of content if such exists",
    %{repository: repository} do
      raw = """
      # Модули, функции и рекурсия

      Организацията на кода в Elixir става чрез модули.
      """
      meta = Meta.from_file(
        "modules_functions_recursion.md", repository,
        raw, "modules_functions_recursion"
      )

      assert meta.title == "Модули, функции и рекурсия"
    end

    test "inline meta overrides file meta",
    %{repository: repository} do
      raw = """
      category: Програма

      <><><><><><><><>

      # Модули, функции и рекурсия
      """
      meta = Meta.from_file(
        "modules_functions_recursion.md", repository,
        raw, "modules_functions_recursion"
      )

      assert meta.category == "Програма"
    end
  end
end
