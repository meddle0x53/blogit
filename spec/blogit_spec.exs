defmodule BlogitSpec do
  use ESpec

  describe "list_posts" do
    it "returns a list of all the posts, sorted by creation date" do
      expect Blogit.list_posts()
      |> Enum.map(fn(post)-> post.meta.created_at end)
      |> to(eq [
        ~N[2017-02-02 17:02:12], ~N[2017-02-02 15:05:15],
        ~N[2017-02-01 17:02:12], ~N[2017-01-31 17:02:12],
        ~N[2017-01-23 13:17:35], ~N[2017-01-23 13:17:35],
        ~N[2017-01-22 17:02:12], ~N[2016-05-12 17:32:12],
        ~N[2015-03-03 23:21:11], ~N[2015-03-02 17:32:12],
        ~N[2015-03-02 17:32:12]
      ])
    end
  end

  describe "filter_posts" do
    it "filters using the params given the list of posts" do
      params = %{"tags" => "one", "category" => "one", "author" => "Misho"}
      expect Blogit.filter_posts(params)
      |> Enum.map(fn(post)-> post.name end)
      |> to(eq ~w(post7))
    end

    it "returns posts sorted by the creation date" do
      params = %{"tags" => "one"}
      expect Blogit.filter_posts(params)
      |> Enum.map(fn(post)-> post.name end)
      |> to(eq ~w(post6 post7 post2 post3 post1))
    end
  end
end
