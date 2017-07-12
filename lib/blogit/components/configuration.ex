defmodule Blogit.Components.Configuration do
  @moduledoc """
  A component GenServer process which can be queried from outside.
  The Blogit.Components.Configuration process holds the configuration of the
  blog.

  This process handles one call - `:get`. When received, the configuration
  of the blog is returned in the form of Blogit.Models.Configuration.

  This component is supervised by Blogit.Components.Supervisor and added to
  it by Blogit.Server.
  When the configuration gets updated, this process' state is updated
  by the Blogit.Server process.
  """

  use GenServer

  @base_name :configuration

  def base_name, do: @base_name
  def name(language), do: :"#{base_name()}_#{language}"

  def start_link(language \\ Blogit.Settings.default_language()) do
    GenServer.start_link(__MODULE__, language, name: name(language))
  end

  def init(language) do
    send(self(), :init_configuration)
    {:ok, %{language: language}}
  end

  def handle_info(:init_configuration, %{language: language}) do
    configuration =
      GenServer.call(Blogit.Server, {:get_configuration, language})

    {:noreply, %{language: language, configuration: configuration}}
  end

  def handle_cast({:update, new_configuration}, state) do
    {:noreply, %{state | configuration: new_configuration}}
  end

  def handle_call(:get, _from, %{configuration: configuration} = state) do
    {:reply, configuration, state}
  end
end
