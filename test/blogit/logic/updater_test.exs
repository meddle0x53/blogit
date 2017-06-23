defmodule Blogit.Logic.UpdaterTest do
  use ExUnit.Case

  alias Blogit.Logic.Updater

  alias Blogit.Models.Post
  alias Blogit.Models.Configuration

  alias Blogit.RepositoryProviders.Memory

  setup do: Fixtures.posts_in_memory()

  describe ".check_updates" do
    setup %{repository: repository} do
      posts = Post.compile_posts(repository.provider.local_files, repository)
      configuration = Configuration.from_file(repository.provider)
      %{
        state: %Blogit.Server{
          repository: repository, posts: posts, configuration: configuration
        }
      }
    end

    test """
    if no updates present in the repository, returns :no_updates
    """, %{state: state} do
      assert Updater.check_updates(state) == :no_updates
    end

    test """
    if there are new posts they are added to the posts of state and returned
    as part of the tupple {:updates, <new-state>}
    """, %{state: state} do
      Memory.add_post(%Memory.RawPost{author: "valo", path: "meta_one.md"})
      {:updates, %{posts: posts}} = Updater.check_updates(state)

      assert Enum.member?(Map.keys(posts), :meta_one)
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
    if a post was updated it is updated in the state returned as part of the
    tuple {:updated, <new-state>}
    """, %{state: state} do
      updated_post = %Memory.RawPost{
        author: "Reductions", path: "mix.md", content: "Updated!"
      }
      Memory.replace_post(updated_post)
      {:updates, %{posts: posts}} = Updater.check_updates(state)
      contents = Enum.map(Map.values(posts), &(&1.raw))

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
      """
      Memory.add_file("blog.yml", yml)
      {:updates, %{configuration: configuration}} = Updater.check_updates(state)

      assert configuration == %Configuration{
        title: "Test Blog", sub_title: "Testing it now",
        logo_path: "some/image.jpg", styles_path: "some/styles.css",
        background_image_path: "some/other_image.jpg"
      }
    end
  end
end
