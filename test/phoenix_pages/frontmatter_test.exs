defmodule PhoenixPages.FrontmatterTest do
  use ExUnit.Case, async: true

  import PhoenixPages.Frontmatter

  describe "parse/1" do
    test "should parse valid frontmatter" do
      assert parse("---\nfoo: bar\n---\nHello") == %{foo: "bar", raw_content: "Hello"}

      assert parse("---\nfoo: bar\nbaz: [qux, quux]\n---\nHello") == %{
               foo: "bar",
               baz: ["qux", "quux"],
               raw_content: "Hello"
             }
    end

    test "should ignore misformed frontmatter" do
      assert parse("---\nfoo: bar\n--\nHello") == %{raw_content: "---\nfoo: bar\n--\nHello"}
    end

    test "should ignore empty frontmatter" do
      assert parse("---\n---\nHello") == %{raw_content: "Hello"}
      assert parse("Hello") == %{raw_content: "Hello"}
    end

    test "should raise error with invalid frontmatter" do
      assert_raise PhoenixPages.Error, "could not parse foo.md", fn ->
        parse("---\nfoo\nbar baz\n---\nHello", "foo.md")
      end
    end

    test "should raise error when yaml_elixir does not return map" do
      assert_raise PhoenixPages.Error, "could not parse foo.md", fn ->
        parse("---\nfoo bar\n---\nHello", "foo.md")
      end
    end
  end

  describe "cast/2" do
    test "should cast a list of required fields" do
      assert cast(%{raw_content: "", foo: "bar"}, [:foo]) == %{raw_content: "", foo: "bar"}
      assert cast(%{raw_content: "", foo: ["bar"]}, [:foo]) == %{raw_content: "", foo: ["bar"]}
    end

    test "should raise error if a required field is missing" do
      assert_raise KeyError, fn -> cast(%{raw_content: ""}, [:foo]) end
    end

    test "should ignore non-cast fields" do
      assert cast(%{raw_content: "", foo: "bar", baz: "qux"}, [:foo]) == %{raw_content: "", foo: "bar"}
    end

    test "should add field defaults" do
      assert cast(%{raw_content: ""}, foo: "bar") == %{raw_content: "", foo: "bar"}

      assert cast(%{raw_content: "", foo: "bar", baz: "baz"}, [:foo, baz: "qux"]) == %{
               raw_content: "",
               foo: "bar",
               baz: "baz"
             }
    end
  end
end
