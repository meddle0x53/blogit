defmodule Blogit.Components.ConfigurationTest do
  alias Blogit.Components.Configuration
  use ComponentTestCase, setup_posts: false, module: Configuration

  setup do: %{pid: DummyServer.setup_configuration()}

  test "`configuration` state is calculated from the provider", %{pid: pid} do
    %{language: language, configuration: configuration} = :sys.get_state(pid)

    assert language == Settings.default_language()
    refute is_nil(configuration)

    assert configuration == %Blogit.Models.Configuration{
             background_image_path: nil,
             language: "bg",
             logo_path: nil,
             social: %{"rss" => true, "stars_for_blogit" => true},
             styles_path: nil,
             sub_title: nil,
             title: "Memory"
           }
  end

  test "cast `{:update, configuration}`, overides the state", %{pid: pid} do
    GenServer.cast(pid, {:update, %Blogit.Models.Configuration{title: "one"}})

    %{configuration: configuration} = :sys.get_state(pid)

    assert configuration == %Blogit.Models.Configuration{title: "one"}
  end

  test "call `:get`, returns the configuration state", %{pid: pid} do
    configuration = GenServer.call(pid, :get)

    assert configuration == %Blogit.Models.Configuration{
             background_image_path: nil,
             language: "bg",
             logo_path: nil,
             social: %{"rss" => true, "stars_for_blogit" => true},
             styles_path: nil,
             sub_title: nil,
             title: "Memory"
           }
  end
end
