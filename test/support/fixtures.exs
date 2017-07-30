defmodule Fixtures do
  alias Blogit.RepositoryProviders.Memory
  alias Blogit.RepositoryProviders.Memory.RawPost
  alias Blogit.RepositoryProvider, as: Repository

  @raw_posts [
    %RawPost{
      author: "meddle", path: "processes.md", content: "Stuff",
      created_at: "2017-06-21 08:46:50"
    },
    %RawPost{
      author: nil, path: "modules_functions_recursion.md",
      created_at: "2017-06-05 08:46:50",
      updated_at: "2017-06-11 08:46:50",
      content: """
      ---
      title_image_path: modules.jpg
      category: Програма
      author: valo
      pinned: true
      category: Program
      published: true
      tags:
        - elixir
        - modules
        - functions
        - recursion
      ---

      # Модули, функции и рекурсия

      Организацията на кода в Elixir става чрез модули.
      Модулите просто групират множество функции,
      като обикновенно идеята е функциите в даден модул да извършват някаква
      обща работа.

      Така и когато ние пишем програма на Elixir ще разбиваме
      функционалността на функции и ще ги групираме в модули.

      ## Дефиниране на модул

      Нека да видим един прост пример за модул с една фунцкия:
      """
    },
    %RawPost{
      author: "Reductions", path: "mix.md", created_at: "2017-05-30 21:26:49"
    },
    %RawPost{
      author: "meddle", path: "en/mix.md", created_at: "2017-07-27 08:38:37"
    },
    %RawPost{
      author: "Andreshk", path: "control_flow_and_errors.md",
      created_at: "2016-05-25 07:36:29"
    },
    %RawPost{
      author: "meddle", path: "otp.md", created_at: "2017-06-15 05:37:10",
      content: """
      ---
      tags:
        - ab
        - cd
      ---
      OTP!
      """
    },
    %RawPost{
      author: "meddle", path: "pro_nodes.md", created_at: "2017-06-10 18:52:49",
      updated_at: "2017-06-10 18:52:49",
      content: """
      ---
      pinned: true
      category: Some
      published: false
      ---

      # Title\n Some text...\n## Section 1\n Hey!!\n* i1\n * i2
      """
    },
    %RawPost{
      author: "meddle", path: "nodes.md", created_at: "2017-06-10 18:52:49",
      updated_at: "2017-06-10 18:52:49",
      content: """
      ---
      pinned: true
      category: Some
      ---

      # Title\n Some text...\n## Section 1\n Hey!!\n* i1\n * i2
      """
    },
    %RawPost{author: "valo", path: "plug.md", created_at: "2017-06-20 09:12:32"}
  ]

  def posts, do: @raw_posts

  def posts_in_memory do
    {:ok, _} = Memory.start_link(%Memory{raw_posts: @raw_posts})

    %{repository: %Repository{provider: Memory}}
  end

  def stop do
    pid = Process.whereis(Memory)

    if !is_nil(pid) && Process.alive?(pid) do
      Agent.stop(Memory)
    end
  end

  def setup do
    result = Fixtures.posts_in_memory()

    ExUnit.Callbacks.on_exit(&Fixtures.stop/0)

    result
  end
end
