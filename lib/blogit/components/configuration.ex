defmodule Blogit.Components.Configuration do
  @moduledoc """
  A `Blogit.Component` process which can be queried from outside.
  The `Blogit.Components.Configuration` process holds the configuration of the
  blog.

  This process handles one call - `:get`. When received, the configuration
  of the blog is returned in the form of `Blogit.Models.Configuration` struct.

  This component is supervised by `Blogit.Components.Supervisor` and added to
  it by `Blogit.Server`.
  When the configuration gets updated, this process' state is updated
  by the `Blogit.Server` process.
  """

  use Blogit.Component

  def init({language, configuration_provider}) do
    send(self(), {:init_configuration, configuration_provider})
    {:ok, %{language: language}}
  end

  def handle_info({:init_configuration, provider}, %{language: language}) do
    configuration = provider.get_configuration(language)

    {:noreply, %{language: language, configuration: configuration}}
  end

  def handle_cast({:update, new_configuration}, state) do
    {:noreply, %{state | configuration: new_configuration}}
  end

  def handle_call(:get, _from, %{configuration: configuration} = state) do
    {:reply, configuration, state}
  end
end
