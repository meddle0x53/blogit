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

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :init_configuration)
    {:ok, nil}
  end

  def handle_info(:init_configuration, nil) do
    configuration = GenServer.call(Blogit.Server, :get_configuration)

    {:noreply, configuration}
  end

  def handle_cast({:update, new_configuration}, _) do
    {:noreply, new_configuration}
  end

  def handle_call(:get, _from, configuration) do
    {:reply, configuration, configuration}
  end
end
