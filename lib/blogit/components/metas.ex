defmodule Blogit.Components.Metas do
  @moduledoc """
  A component `GenServer` process which can be queried from outside.
  The `Blogit.Components.Metas` process holds the meta data for all the post
  in the blog as its state.

  For some queries only the meta data of the posts is needed and quering this
  component for it is faster than retrieving it from the
  `Blogit.Components.Posts` one. Also the messages with only meta data are
  much smaller, as they only include the preview HTML of the posts and not the
  whole content.

  This process handles the following `call` messages:
  * {:list, from, size} -> returns a list of post metas sorted by their
    created_at field, newest first. The first `from` are dropped and
    the size of the result list is specified by `size`. The `size` can be
    `:infinity`.
  * :list_pinned -> returns a list of `Blogit.Models.Post.Meta` structures,
    sorted by their `updated_at` field, newest first, only if their `pinned`
    field is `true`.

  This component is supervised by `Blogit.Components.Supervisor` and added to
  it by `Blogit.Server`.
  When the posts get updated, this process' state is reset to nil and on the
  next request to it, it is re-calculated.
  """

  use GenServer

  alias Blogit.Settings

  @base_name :metas

  def base_name, do: @base_name
  def name(language), do: :"#{base_name()}_#{language}"

  alias Blogit.Components.Posts
  alias Blogit.Models.Post.Meta

  def start_link(language \\ Settings.default_language()) do
    GenServer.start_link(__MODULE__, language, name: name(language))
  end

  def init(language) do
    {:ok, %{language: language, metas: nil}}
  end

  def handle_cast(:reset, %{language: language}) do
    {:noreply, %{language: language, metas: nil}}
  end

  def handle_call({:list, from, size}, _, %{metas: metas, language: lang}) do
    post_metas = get(metas, lang)
    take = if size == :infinity, do: length(post_metas), else: size

    result = post_metas |> Enum.drop(from) |> Enum.take(take)

    {:reply, result, %{language: lang, metas: post_metas}}
  end

  def handle_call(:list_pinned, _from, %{metas: metas, language: lang}) do
    post_metas = get(metas, lang)
    result = post_metas
             |> Enum.filter(&(&1.pinned))
             |> Meta.sorted(:updated_at)
             |> Enum.map(fn meta -> {meta.name, meta.title} end)

    {:reply, result, %{language: lang, metas: post_metas}}
  end

  defp get(nil, language) do
    posts = GenServer.call(Posts.name(language), :all)
    posts |> Enum.map(&(&1.meta)) |> Meta.sorted()
  end

  defp get(metas, _), do: metas
end
