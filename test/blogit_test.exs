defmodule BlogitTest do
  use ExUnit.Case

  defp wait_for_update do
    updated =
      Agent.get(Blogit.RepositoryProviders.Memory, fn data ->
        Enum.empty?(data.updates)
      end)

    case updated do
      true -> :ok
      false ->
        Process.sleep(100)
        wait_for_update()
    end
  end

  setup do
    {:ok, _} = Application.ensure_all_started(:blogit)

    :sys.get_state(Process.whereis(Blogit.Server))

    Agent.update(Blogit.RepositoryProviders.Memory, fn data ->
      %{data |
        raw_posts: Fixtures.posts(),
        updates: Enum.map(Fixtures.posts(), &(&1.path))
      }
    end)

    send(Process.whereis(Blogit.Server), :check_updates)
    wait_for_update()

    on_exit fn ->
      Application.stop(:blogit)
    end

    :ok
  end

  describe ".list_posts" do
    test "by default returns the five newest posts" do
      names = Blogit.list_posts() |> Enum.map(&(&1.name))

      assert names == ~w[processes plug otp nodes modules_functions_recursion]
    end

    test """
    returns five (maximum) posts beginning from the given as the first argument
    position, newest first
    """ do
      names = Blogit.list_posts(2) |> Enum.map(&(&1.name))

      assert names == ~w[
        otp nodes modules_functions_recursion mix control_flow_and_errors
      ]
    end

    test """
    returns N (maximum) posts beginning from the given as the first argument
    position, newest first. N is the second argument given.
    """ do
      names = Blogit.list_posts(2, 3) |> Enum.map(&(&1.name))

      assert names == ~w[otp nodes modules_functions_recursion]
    end
  end

  describe ".list_pinned" do
    test """
    returns a list of the pinned posts (the ones with pinned: true in their
    meta data), ordered by their last update date. The most recently updated
    first.
    """ do
      names = Blogit.list_pinned() |> Enum.map(&(elem(&1, 0)))

      assert names == ~w[modules_functions_recursion nodes]
    end
  end

  describe ".filter_posts" do
    test "filters posts by author, the list is sorted with newest first" do
      names = Blogit.filter_posts(%{"author" => "valo"}) |> Enum.map(& &1.name)

      assert names == ~w[plug modules_functions_recursion]
    end

    test "filters posts by category, the list is sorted with newest first" do
      names =
        Blogit.filter_posts(%{"category" => "Some"}) |> Enum.map(& &1.name)

      assert names == ~w[nodes]
    end

    test "filters posts by tags, the list is sorted with newest first" do
      names =
        Blogit.filter_posts(%{"tags" => ~s[ab,cd]}) |> Enum.map(& &1.name)

      assert names == ~w[otp]
    end

    test "filters posts by year, the list is sorted with newest first" do
      names =
        Blogit.filter_posts(%{"year" => "2016"}) |> Enum.map(& &1.name)

      assert names == ~w[control_flow_and_errors]
    end

    test "filters posts by month, the list is sorted with newest first" do
      names =
        Blogit.filter_posts(%{"month" => "5"}) |> Enum.map(& &1.name)

      assert names == ~w[mix control_flow_and_errors]
    end

    test "filters posts by query, the list is sorted with newest first" do
      names =
        Blogit.filter_posts(%{"q" => "Stuff"}) |> Enum.map(& &1.name)

      assert names == ~w[processes]
    end
  end
end
