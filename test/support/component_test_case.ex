defmodule ComponentTestCase do
  @doc false
  defmacro __using__(setup_posts: setup_posts, module: module_name) do
    quote do
      use ExUnit.Case

      alias Blogit.Settings

      if unquote(setup_posts) do
        setup do: %{posts_pid: DummyServer.setup_posts()}
      end

      test "defines a component process", %{pid: pid} do
        assert is_pid(pid)
        assert Process.alive?(pid)

        module = unquote(module_name)
        expected_name =
          String.to_atom("#{module.base_name()}_#{Settings.default_language()}")
        assert module.name(Settings.default_language()) == expected_name
      end
    end
  end
end
