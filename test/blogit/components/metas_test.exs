defmodule Blogit.Components.MetasTest do
  alias Blogit.Components.{Metas, Posts}
  use ComponentTestCase, setup_posts: true, module: Metas

  setup do
    {:ok, pid} = Metas.start_link()
    %{pid: pid}
  end

  test "`metas` state is nil initially", %{pid: pid} do
    %{language: language, metas: metas} = :sys.get_state(pid)

    assert language == Settings.default_language()
    assert is_nil(metas)
  end

  test "`metas` state is calculated on the first `{:list, from, size}` call", %{pid: pid} do
    metas = GenServer.call(pid, {:list, 1, 2})

    refute is_nil(metas)
    assert metas |> Enum.map(& &1.name) == ~w(plug otp)
  end

  test "`{:list, 0, :initially}` returns all the meta data", %{pid: pid} do
    metas = GenServer.call(pid, {:list, 0, :infinity})

    refute is_nil(metas)
    assert metas |> Enum.map(& &1.name) == ~w(
      processes plug otp nodes modules_functions_recursion mix
      control_flow_and_errors
    )
  end

  test "the `metas` state is calculated on the first `:list_pinned` call" <>
         " and the pinned post's meta is returned",
       %{pid: pid} do
    metas = GenServer.call(pid, :list_pinned)

    refute is_nil(metas)

    assert metas == [
             {"modules_functions_recursion", "Модули, функции и рекурсия"},
             {"nodes", "Title"}
           ]
  end

  test "a `:reset` cast, sets the `metas` state to nil", %{pid: pid} do
    metas = GenServer.call(pid, :list_pinned)
    refute is_nil(metas)

    GenServer.cast(pid, :reset)

    %{language: language, metas: metas} = :sys.get_state(pid)

    assert language == Settings.default_language()
    assert is_nil(metas)

    new_post = %Blogit.Models.Post{
      name: "One", raw: "", html: "",
      meta: %Blogit.Models.Post.Meta{
        name: "One"
      }
    }
    :ok = GenServer.call(Posts.name(language), {:update, %{one: new_post}})
    metas = GenServer.call(pid, {:list, 0, 2})

    refute is_nil(metas)
    assert metas |> Enum.map(& &1.name) == ~w(One)
  end
end
