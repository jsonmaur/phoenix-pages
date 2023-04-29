defmodule PhoenixPages.FrontmatterTest do
  use ExUnit.Case, async: true

  import PhoenixPages.Frontmatter

  describe "parse/2" do
    test "should parse valid frontmatter" do
      assert parse("---\nfoo: bar\n---\nHello") == {%{foo: "bar"}, "Hello"}
      assert parse("---\nfoo: bar\nbaz: [qux, quux]\n---\nHello") == {%{foo: "bar", baz: ["qux", "quux"]}, "Hello"}
    end

    test "should ignore misformed frontmatter" do
      assert parse("---\nfoo: bar\n--\nHello") == {%{}, "---\nfoo: bar\n--\nHello"}
    end

    test "should ignore empty frontmatter" do
      assert parse("---\n---\nHello") == {%{}, "Hello"}
      assert parse("Hello") == {%{}, "Hello"}
    end

    test "should raise error with invalid frontmatter" do
      assert_raise PhoenixPages.ParseError, "could not parse foo.md", fn ->
        parse("---\nfoo\nbar baz\n---\nHello", "foo.md")
      end
    end

    test "should raise error when yaml_elixir does not return map" do
      assert_raise PhoenixPages.ParseError, "could not parse foo.md", fn ->
        parse("---\nfoo bar\n---\nHello", "foo.md")
      end
    end
  end

  describe "cast/2" do
    test "should cast a list of required fields" do
      assert cast(%{foo: "bar", bar: ["baz", "qux"]}, [:foo, :bar]) == %{foo: "bar", bar: ["baz", "qux"]}
    end

    test "should raise error if a required field is missing" do
      assert_raise KeyError, fn -> cast(%{}, [:foo]) end
    end

    test "should ignore non-cast fields" do
      assert cast(%{foo: "bar", baz: "qux"}, [:foo]) == %{foo: "bar"}
    end

    test "should add field defaults" do
      assert cast(%{}, foo: "bar") == %{foo: "bar"}
      assert cast(%{foo: "bar", baz: "baz"}, [:foo, baz: "qux"]) == %{foo: "bar", baz: "baz"}
    end
  end
end
