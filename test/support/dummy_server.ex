defmodule DummyServer do
  alias Blogit.Settings
  alias Blogit.Components.Posts
  alias Blogit.Components.Configuration
  alias Blogit.RepositoryProviders.Memory

  def get_posts(language) do
    repository = %Blogit.RepositoryProvider{repo: nil, provider: Memory}
    posts = Blogit.Models.Post.compile_posts(Memory.list_files(), repository)

    posts[language]
  end

  def get_configuration(language) do
    configurations = Blogit.Models.Configuration.from_file(Memory)

    configurations |> Enum.find(&(&1.language == language))
  end

  def setup_posts do
    Fixtures.setup()

    start_posts()
  end

  def setup_configuration do
    Fixtures.setup()

    {:ok, pid} = Configuration.start_link(Settings.default_language(), DummyServer)
    pid
  end

  defp start_posts do
    case Posts.start_link(Settings.default_language(), DummyServer) do
      {:ok, pid} ->
        pid

      {:error, _} ->
        Process.sleep(100)
        start_posts()
    end
  end
end
