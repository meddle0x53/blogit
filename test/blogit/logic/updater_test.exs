defmodule Blogit.Logic.UpdaterTest do
  use ExUnit.Case

  alias Blogit.Logic.Updater

  alias Blogit.Models.Post
  alias Blogit.Models.Configuration

  alias Blogit.RepositoryProviders.Memory

  setup do
    Application.ensure_all_started(:yaml_elixir)

    on_exit fn ->
      Application.stop(:yaml_elixir)
    end

    Fixtures.posts_in_memory()
  end

  describe ".check_updates" do
    setup %{repository: repository} do
      posts = Post.compile_posts(repository.provider.local_files, repository)
      configurations = Configuration.from_file(repository.provider)
      %{
        state: %Blogit.Server{
          repository: repository, posts: posts, configurations: configurations,
          languages: configurations |> Enum.map(&(&1.language))
        }
      }
    end

    test """
    if no updates present in the repository, returns :no_updates
    """, %{state: state} do
      assert Updater.check_updates(state) == :no_updates
    end

    test """
    if there are new posts they are added to the posts of the given `state`
    and returned as part of the tupple {:updates, <new-state>}
    """, %{state: state} do
      Memory.add_post(%Memory.RawPost{author: "valo", path: "meta_one.md"})
      {:updates, %{posts: posts}} = Updater.check_updates(state)
      names = Map.keys(posts[Blogit.Settings.default_language()])

      assert Enum.member?(names, :meta_one)
    end

    test """
    if a post was deleted it is removed from the the state returned as part
    of the tuple {:updated, <new-state>}
    """, %{state: state} do
      Memory.delete_post("mix.md")
      {:updates, %{posts: posts}} = Updater.check_updates(state)

      refute Enum.member?(Map.keys(posts), :mix)
    end

    test """
    if a post was updated its state becomes the new-state returned as part of
    the tuple {:updated, <new-state>}
    """, %{state: state} do
      updated_post = %Memory.RawPost{
        author: "Reductions", path: "mix.md", content: "Updated!"
      }
      Memory.replace_post(updated_post)

      {:updates, %{posts: posts}} = Updater.check_updates(state)
      posts = Map.values(posts[Blogit.Settings.default_language()])
      contents = Enum.map(posts, &(&1.raw))

      assert Enum.member?(contents, "Updated!")
    end

    test """
    if the configuration of the blog was updated it is returned as part of the
    state in the tupple {:updated, <new-state>}
    """, %{state: state} do
      yml = """
      title: Test Blog
      sub_title: Testing it now
      logo_path: some/image.jpg
      styles_path: some/styles.css
      background_image_path: some/other_image.jpg
      language: bg
      """
      Memory.add_file("blog.yml", yml)
      {:updates, %{configurations: configurations}} =
        Updater.check_updates(state)

      assert List.first(configurations) == %Configuration{
        title: "Test Blog", sub_title: "Testing it now",
        logo_path: "some/image.jpg", styles_path: "some/styles.css",
        background_image_path: "some/other_image.jpg",
        language: ~s(bg)
      }
    end
  end
end
