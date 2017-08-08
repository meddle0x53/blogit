defmodule Blogit.Components.PostsByDateTest do
  alias Blogit.Components.PostsByDate
  use ComponentTestCase, setup_posts: true, module: PostsByDate

  setup do
    {:ok, pid} = PostsByDate.start_link()
    %{pid: pid}
  end

  test "`posts_by_dates` state is nil initially", %{pid: pid} do
    %{language: language, posts_by_dates: posts_by_dates} = :sys.get_state(pid)

    assert language == Settings.default_language()
    assert is_nil(posts_by_dates)
  end

  test "`posts_by_dates` state is calculated on the first get", %{pid: pid} do
    posts_by_dates = GenServer.call(pid, :get)

    refute is_nil(posts_by_dates)
    assert posts_by_dates == [{2017, 6, 5}, {2017, 5, 1}, {2016, 5, 1}]
  end
end
