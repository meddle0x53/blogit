defmodule Blogit.ComponentTest do
  use ExUnit.Case, async: true

  defmodule TestComponent do
    use Blogit.Component

    def init({language, _}), do: {:ok, %{language: language}}
  end

  defmodule AnotherTestComponent do
    use Blogit.Component, base_name: "another_component"
  end

  describe "when a module uses it with `use Blogit.Component`" do
    test "injects a function base_name/0, which returns the name of " <>
    "the module in underscore case" do
      assert TestComponent.base_name() == "test_component"
    end

    test "if `base_name: String` is passed to `use Blogit.Component`, " <>
    "`base_name/0` returns it" do
      assert AnotherTestComponent.base_name() == "another_component"
    end

    test "injects a function name/1, which returns the atom " <>
    ~s[`:"base_name() <> "the-given-language"`] do
      assert TestComponent.name("en") == :test_component_en
    end

    test "injects a function start_link/2 which starts a GenServer process " <>
    "with name `name(Blogit.Settings.default_language())` if no language " <>
    "given" do
      assert Blogit.Settings.default_language() == "bg"

      {:ok, pid} = TestComponent.start_link()

      assert is_pid(pid)
      assert Process.alive?(pid)
      assert Process.whereis(:test_component_bg) == pid
    end

    test "injects a function start_link/1 which starts a GenServer process " <>
    "with name `name(language)` if a language is given" do
      {:ok, pid} = TestComponent.start_link("en")

      assert is_pid(pid)
      assert Process.alive?(pid)
      assert Process.whereis(:test_component_en) == pid
    end

    test "injects a function start_link/1 which starts a GenServer process " <>
    "and passes the given language to the `init/1` callback of the GenServer" do
      {:ok, pid} = TestComponent.start_link("en")

      assert :sys.get_state(pid) == %{language: "en"}
    end
  end
end
