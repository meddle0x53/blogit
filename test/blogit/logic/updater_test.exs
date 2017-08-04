defmodule Blogit.Logic.UpdaterTest do
  use ExUnit.Case

  alias Blogit.Logic.Updater

  alias Blogit.Models.Post
  alias Blogit.Models.Configuration

  alias Blogit.RepositoryProviders.Memory

  setup do
    Application.put_env(:blogit, :configuration_file, "blog.yml")
    Fixtures.setup()
  end

  describe "check_updates" do
    setup %{repository: repository} do
      posts = Post.compile_posts(repository.provider.list_files, repository)
      configurations = Configuration.from_file(repository.provider)
      %{
        state: %Blogit.Server{
          repository: repository, posts: posts, configurations: configurations
        }
      }
    end

    test "if no updates present in the repository, returns :no_updates",
    %{state: state} do
      assert Updater.check_updates(state) == :no_updates
    end

    test """
    if there are new posts they are added to the posts of the given `state`
    and returned as part of the tupple `{:updates, <new-state>}`
    """, %{state: state} do
      Memory.add_post(%Memory.RawPost{author: "valo", path: "meta_one.md"})
      {:updates, %{posts: posts}} = Updater.check_updates(state)
      names = Map.keys(posts[Blogit.Settings.default_language()])

      assert Enum.member?(names, :meta_one)
    end

    test """
    if there are new posts they are added to the posts of the given `state`
    and returned as part of the tupple `{:updates, <new-state>}`; alt locale
    """, %{state: state} do
      Memory.add_post(%Memory.RawPost{author: "valo", path: "en/meta_one.md"})
      {:updates, %{posts: posts}} = Updater.check_updates(state)
      post = posts["en"][:meta_one]

      refute is_nil(post)
      assert post.meta.author == "valo"
    end

    test """
    if there are new posts they are added to the posts of the given `state`
    and returned as part of the tupple `{:updates, <new-state>}`; multiple
    """, %{state: state} do
      Memory.add_post(%Memory.RawPost{author: "valo", path: "meta_one.md"})
      Memory.add_post(%Memory.RawPost{author: "valo", path: "en/meta_one.md"})
      Memory.add_post(%Memory.RawPost{author: "valo", path: "meta_two.md"})
      {:updates, %{posts: posts}} = Updater.check_updates(state)
      names = Map.keys(posts[Blogit.Settings.default_language()])

      assert Enum.member?(names, :meta_one)
      assert Enum.member?(names, :meta_two)

      names = Map.keys(posts["en"])

      assert Enum.member?(names, :meta_one)
    end

    test "if a post was deleted it is removed from the the state returned " <>
    "as part of the tuple `{:updated, <new-state>}`" , %{state: state} do
      Memory.delete_post("mix.md")
      {:updates, %{posts: posts}} = Updater.check_updates(state)
      names = Map.keys(posts[Blogit.Settings.default_language()])

      refute Enum.member?(names, :mix)
    end

    test "if a post was deleted it is removed from the the state returned " <>
    "as part of the tuple `{:updated, <new-state>}`; alt locale" ,
    %{state: state} do
      Memory.delete_post("en/mix.md")
      {:updates, %{posts: posts}} = Updater.check_updates(state)
      names = Map.keys(posts["en"])

      refute Enum.member?(names, :mix)
    end

    test "if a post was deleted it is removed from the the state returned " <>
    "as part of the tuple `{:updated, <new-state>}`; multiple" ,
    %{state: state} do
      Memory.delete_post("en/mix.md")
      Memory.delete_post("nodes.md")
      {:updates, %{posts: posts}} = Updater.check_updates(state)

      names = Map.keys(posts["en"])
      refute Enum.member?(names, :mix)

      names = Map.keys(posts["bg"])
      refute Enum.member?(names, :nodes)
    end

    test "if a post was updated its state becomes the new-state returned " <>
    "as part of the tuple {:updated, <new-state>}", %{state: state} do
      updated_post = %Memory.RawPost{
        author: "Reductions", path: "mix.md", content: "Updated!"
      }
      Memory.replace_post(updated_post)

      {:updates, %{posts: posts}} = Updater.check_updates(state)
      posts = Map.values(posts[Blogit.Settings.default_language()])
      contents = Enum.map(posts, &(&1.raw))

      assert Enum.member?(contents, "Updated!")
    end

    test "if a post was updated its state becomes the new-state returned " <>
    "as part of the tuple {:updated, <new-state>}; alt locale",
    %{state: state} do
      updated_post = %Memory.RawPost{
        author: "Reductions", path: "en/mix.md", content: "Updated!"
      }
      Memory.replace_post(updated_post)

      {:updates, %{posts: posts}} = Updater.check_updates(state)
      posts = Map.values(posts["en"])
      contents = Enum.map(posts, &(&1.raw))

      assert Enum.member?(contents, "Updated!")
    end

    test "if the configuration of the blog was updated it is returned " <>
    "as part of the state in the tupple {:updated, <new-state>}",
    %{state: state} do
      yml = """
      title: Test Blog
      sub_title: Testing it now
      logo_path: some/image.jpg
      styles_path: some/styles.css
      background_image_path: some/other_image.jpg
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

    test "if the configuration of the blog was updated it is returned " <>
    "as part of the state in the tupple {:updated, <new-state>}; alt locale",
    %{state: state} do
      yml = """
      title: Test blog
      sub_title: SOS
      logo_path: some/image.jpg
      styles_path: some/styles.css
      background_image_path: some/other_image.jpg
      en:
        title: WOW
      """
      Memory.add_file("blog.yml", yml)
      {:updates, %{configurations: configurations}} =
        Updater.check_updates(state)

        assert configurations == [
          %Configuration{
            title: "Test blog", sub_title: "SOS", language: ~s(bg),
            logo_path: "some/image.jpg", styles_path: "some/styles.css",
            background_image_path: "some/other_image.jpg"
          },
          %Configuration{
            title: "WOW", sub_title: "SOS", language: ~s(en),
            logo_path: "some/image.jpg", styles_path: "some/styles.css",
            background_image_path: "some/other_image.jpg"
          }
        ]
    end
  end
end
