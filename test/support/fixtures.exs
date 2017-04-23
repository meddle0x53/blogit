defmodule Fixtures do
  alias Blogit.RepositoryProviders.Memory
  alias Blogit.RepositoryProviders.Memory.RawPost
  alias Blogit.RepositoryProvider, as: Repository

  def posts_in_memory do
    raw_posts = [
      %RawPost{author: "meddle", path: "processes.md", content: "Stuff"},
      %RawPost{
        author: nil, path: "modules_functions_recursion.md",
        meta: "pinned: true\ncategory: Program\npublished: false",
        content: """
        title_image_path: modules.jpg
        category: Програма
        author: valo
        tags:
        - elixir
        - modules
        - functions
        - recursion

        <><><><><><><><>

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
      %RawPost{author: "Reductions", path: "mix.md"},
      %RawPost{author: "Andreshk", path: "control_flow_and_errors.md"}
    ]

    Memory.start_link(%Memory{raw_posts: raw_posts})

    %{repository: %Repository{provider: Memory}}
  end
end
