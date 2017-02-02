defmodule SearchSpec do
  use ESpec
  alias Blogit.Search

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
