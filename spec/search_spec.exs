defmodule SearchSpec do
  use ESpec
  alias Blogit.Search

  let :posts, do: Blogit.list_posts

  describe "filter_by_params" do
    it "can filter posts by author" do
      expect Search.filter_by_params(posts(), %{"author" => "Pesho"})
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post6 post1))
    end

    it "can filter posts by category" do
      expect Search.filter_by_params(posts(), %{"category" => "one"})
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post7 post3 post1))
    end

    it "can filter posts without a category using category: uncategorized" do
      expect Search.filter_by_params(posts(), %{"category" => "uncategorized"})
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post6 test_with_title test_with_no_title))
    end

    it "can filter posts without a category using category: nil" do
      expect Search.filter_by_params(posts(), %{"category" => nil})
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post6 test_with_title test_with_no_title))
    end

    it "can filter posts by category AND author" do
      params = %{"category" => "one", "author" => "Pesho"}
      expect Search.filter_by_params(posts(), params)
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post1))
    end

    it "can filter posts by tags" do
      params = %{"tags" => "one,two"}
      expect Search.filter_by_params(posts(), params)
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post6 post2 post1))
    end

    it "can filter posts by tags AND category" do
      params = %{"tags" => "one,two", "category" => "one"}
      expect Search.filter_by_params(posts(), params)
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post1))
    end

    it "can filter posts by tags AND category AND author" do
      params = %{"tags" => "one", "category" => "one", "author" => "Misho"}
      expect Search.filter_by_params(posts(), params)
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post7))
    end

    it "can filter by year" do
      params = %{"year" => "2015"}
      expect Search.filter_by_params(posts(), params)
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(test_with_meta post3 post1))
    end

    it "can filter by year AND month" do
      params = %{"year" => "2017", "month" => "1"}
      expect Search.filter_by_params(posts(), params)
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post7 test_with_title test_with_no_title post4))
    end

    it "can filter by search criteria" do
      params = %{"q" => "dogs"}
      expect Search.filter_by_params(posts(), params)
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post6 post7))
    end

    it "can filter by search query and other criteria" do
      params = %{"q" => "dogs", "author" => "Misho"}
      expect Search.filter_by_params(posts(), params)
      |> Enum.map(fn post -> post.name end)
      |> to(eq ~w(post7))
    end
  end

  describe "query_to_list" do
    it "turns a simple query of terms seaprated by spaces to list" do
      expect Search.query_to_list("one two three")
      |> to(eq ~w(one two three))
    end

    it "handles double-quoted strings as single terms" do
      expect Search.query_to_list("\"one two\"")
      |> to(eq ["one two"])
    end

    it "handles double-quoted terms mixed with additional terms" do
      expect Search.query_to_list("\"one two\" три четири \"пет шест\"")
      |> to(eq ["one two", "три", "четири", "пет шест"])
    end
  end
end
