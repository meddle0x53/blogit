defmodule Blogit.Components.Configuration do
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
