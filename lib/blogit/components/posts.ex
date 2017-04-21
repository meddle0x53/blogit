defmodule Blogit.Components.Posts do
  use GenServer

  alias Blogit.Models.Post
  alias Blogit.Models.Post.Search

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    send(self(), :init_posts)
    {:ok, nil}
  end

  def handle_info(:init_posts, nil) do
    posts = GenServer.call(Blogit.Server, :get_posts)
    {:noreply, posts}
  end

  def handle_cast({:update, new_posts}, _) do
    {:noreply, new_posts}
  end

  def handle_call(:all, _from, posts) do
    {:reply, Map.values(posts), posts}
  end

  def handle_call({:list, from, size}, _from, posts) do
    result = Map.values(posts)
             |> Post.sorted |> Enum.drop(from) |> Enum.take(size)

    {:reply, result, posts}
  end

  def handle_call(:list_pinned, _from, posts) do
    result = Map.values(posts)
             |> Enum.filter(fn post -> post.meta.pinned end)
             |> Post.sorted_updated
             |> Enum.map(fn post -> {post.name, post.meta.title} end)

    {:reply, result, posts}
  end

  def handle_call({:filter, filters, from, size}, _from, posts) do
    result = Map.values(posts) |> Search.filter_by_params(filters)
             |> Post.sorted |> Enum.drop(from) |> Enum.take(size)

    {:reply, result, posts}
  end

  def handle_call({:by_name, name}, _from, posts) do
    case post = posts[name] do
      nil -> {:reply, :error, posts}
      _ -> {:reply, post, posts}
    end
  end
end
