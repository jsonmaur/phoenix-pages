defmodule PhoenixPagesTest do
  use ExUnit.Case, async: true

  @fixtures_path Path.expand("fixtures", __DIR__)

  test "list_files/2" do
    assert {[file1, file2], hash} = PhoenixPages.list_files(@fixtures_path, "**/*.md")
    assert file1 =~ "test/fixtures/foo.md"
    assert file2 =~ "test/fixtures/foo/bar.md"
    assert byte_size(hash) == 16
  end

  describe "render/3" do
    setup do
      %{
        md: %{content: "# Hello"},
        txt: %{content: "Hello"}
      }
    end

    test "should render a markdown file", ctx do
      assert PhoenixPages.render(ctx.md, "foobar.md", []).inner_content == {:safe, "<h1>\nHello</h1>\n"}
      assert PhoenixPages.render(ctx.md, "foobar.markdown", []).inner_content == {:safe, "<h1>\nHello</h1>\n"}
    end

    test "should render a markdown file with options", ctx do
      assert PhoenixPages.render(ctx.md, "foobar.md", compact_output: true).inner_content == {:safe, "<h1>Hello</h1>"}
    end

    test "should render a raw text file", ctx do
      assert PhoenixPages.render(ctx.txt, "foobar.txt", []).content == "Hello"
      refute PhoenixPages.render(ctx.txt, "foobar.txt", [])[:inner_content]
    end
  end

  describe "parse_frontmatter/1" do
    test "should parse valid frontmatter" do
      assert PhoenixPages.parse_frontmatter("---\nfoo: bar\n---\nHello") == %{foo: "bar", content: "Hello"}

      assert PhoenixPages.parse_frontmatter("---\nfoo: bar\nbaz: [qux, quux]\n---\nHello") == %{
               foo: "bar",
               baz: ["qux", "quux"],
               content: "Hello"
             }
    end

    test "should ignore misformed frontmatter" do
      assert PhoenixPages.parse_frontmatter("---\nfoo: bar\n--\nHello") == %{content: "---\nfoo: bar\n--\nHello"}
    end

    test "should ignore empty frontmatter" do
      assert PhoenixPages.parse_frontmatter("---\n---\nHello") == %{content: "Hello"}
      assert PhoenixPages.parse_frontmatter("Hello") == %{content: "Hello"}
    end

    test "should raise error with invalid frontmatter" do
      assert_raise PhoenixPages.ParseError, "could not parse foo.md", fn ->
        PhoenixPages.parse_frontmatter("---\nfoo\nbar baz\n---\nHello", "foo.md")
      end
    end

    test "should raise error when yaml_elixir does not return map" do
      assert_raise PhoenixPages.ParseError, "could not parse foo.md", fn ->
        PhoenixPages.parse_frontmatter("---\nfoo bar\n---\nHello", "foo.md")
      end
    end
  end

  test "filename_to_slug/1" do
    assert PhoenixPages.filename_to_slug("foo.md") == "foo"
    assert PhoenixPages.filename_to_slug("foo/bar.md") == "bar"
    assert PhoenixPages.filename_to_slug("/foo/bar.md") == "bar"
    assert PhoenixPages.filename_to_slug("/foo/bar/baz/qux.md") == "qux"
    assert PhoenixPages.filename_to_slug(" foo bar.md") == "foo-bar"
    assert PhoenixPages.filename_to_slug(" foo   bar .md") == "foo-bar"
    assert PhoenixPages.filename_to_slug("FOO_BAR.md") == "foo-bar"
    assert PhoenixPages.filename_to_slug("foo__bar.md") == "foo-bar"
    assert PhoenixPages.filename_to_slug("foo/bar%baz.md") == "bar-baz"
    assert PhoenixPages.filename_to_slug("foo/bar%123.md") == "bar-123"
  end

  describe "filename_into_path/3" do
    test "should put capture groups into page segment" do
      assert PhoenixPages.filename_into_path(":page", "foo.md", "*.md") == "foo"
      assert PhoenixPages.filename_into_path("/:page", "foo.md", "*.md") == "/foo"
      assert PhoenixPages.filename_into_path("/:page", "/foo.md", "*.md") == "/foo"
      assert PhoenixPages.filename_into_path("/:page/", "foo.md", "*.md") == "/foo/"
      assert PhoenixPages.filename_into_path("/:page/bar", "foo.md", "*.md") == "/foo/bar"
      assert PhoenixPages.filename_into_path("/foo:page", "bar.md", "*.md") == "/foobar"
      assert PhoenixPages.filename_into_path("/:page/:page", "foo.md", "*.md") == "/foo/foo"
      assert PhoenixPages.filename_into_path("/:page", "foo.md", "**/*.md") == "/foo"
      assert PhoenixPages.filename_into_path("/:page", "foo/bar.md", "**/*.md") == "/foo/bar"
      assert PhoenixPages.filename_into_path("/:page", "foo/bar.md", "foo/*.md") == "/bar"
      assert PhoenixPages.filename_into_path("/:page", "foo/bar.md", "foo/**/*.md") == "/bar"
      assert PhoenixPages.filename_into_path("/:page", "/foo/bar.md", "foo/**/*.md") == "/bar"
      assert PhoenixPages.filename_into_path("/:page", "foo/bar/baz.md", "foo/**/*.md") == "/bar/baz"
      assert PhoenixPages.filename_into_path("/:page", "foo/bar/baz/qux/quux.md", "foo/**/qux/*.md") == "/bar/baz/quux"
      assert PhoenixPages.filename_into_path("/:page", "/foo/bar/baz/qux/quux.md", "foo/**/qux/*.md") == "/bar/baz/quux"
    end

    test "should put capture groups into variables" do
      assert PhoenixPages.filename_into_path("$1", "foo.md", "*.md") == "foo"
      assert PhoenixPages.filename_into_path("/$1", "foo.md", "*.md") == "/foo"
      assert PhoenixPages.filename_into_path("/$1/", "foo.md", "*.md") == "/foo/"
      assert PhoenixPages.filename_into_path("/$1/$1", "foo.md", "*.md") == "/foo/foo"
      assert PhoenixPages.filename_into_path("/$1", "foo.md", "**.md") == "/foo"
      assert PhoenixPages.filename_into_path("/foo$1", "bar.md", "**.md") == "/foobar"
      assert PhoenixPages.filename_into_path("/$1", "foo/bar.md", "**.md") == "/foo/bar"
      assert PhoenixPages.filename_into_path("/$1", "foo/bar.md", "**/*.md") == "/foo"
      assert PhoenixPages.filename_into_path("/$1", "foo/bar/baz.md", "**/*.md") == "/foo/bar"
      assert PhoenixPages.filename_into_path("/$2", "foo/bar/baz.md", "**/*.md") == "/baz"
      assert PhoenixPages.filename_into_path("/$1/$2", "foo/bar.md", "foo/*.md") == "/bar/$2"
      assert PhoenixPages.filename_into_path("/$1/$2", "foo/bar/baz/qux.md", "foo/*/baz/*.md") == "/bar/qux"
      assert PhoenixPages.filename_into_path("/$2/$1", "foo/bar/baz/qux.md", "foo/*/baz/*.md") == "/qux/bar"
      assert PhoenixPages.filename_into_path("/$1/$2/", "foo/bar/baz/qux.md", "foo/*/baz/*.md") == "/bar/qux/"
      assert PhoenixPages.filename_into_path("/$1/$2", "foo/bar/baz/qux/quux.md", "foo/**/qux/*.md") == "/bar/baz/quux"
    end

    test "should put capture groups into out-of-order variables" do
      assert PhoenixPages.filename_into_path("/$2/$1/$3", "foo/bar/baz/qux/quux.md", "**/*/qux/*.md") ==
               "/baz/foo/bar/quux"
    end

    test "should put capture groups into page segment and variables" do
      assert PhoenixPages.filename_into_path("/:page/$2", "foo/bar/baz/qux.md", "foo/*/baz/*.md") == "/bar/qux/qux"
    end

    test "should raise error if filename does not match pattern" do
      assert_raise ArgumentError, fn -> PhoenixPages.filename_into_path("/:page", "foo/bar.md", "baz/*.md") end
    end
  end

  test "wildcard_to_regex/1" do
    assert PhoenixPages.wildcard_to_regex("*") == ~r/([^.\/]*)$/
    assert PhoenixPages.wildcard_to_regex("*.md") == ~r/([^.\/]*)\.md$/
    assert PhoenixPages.wildcard_to_regex("**/*.md") == ~r/(.*?)\/?([^.\/]*)\.md$/
    assert PhoenixPages.wildcard_to_regex("foo/*.md") == ~r/foo\/([^.\/]*)\.md$/
    assert PhoenixPages.wildcard_to_regex("foo/**.md") == ~r/foo\/(.*?)\/?\.md$/
    assert PhoenixPages.wildcard_to_regex("foo/**/*.md") == ~r/foo\/(.*?)\/?([^.\/]*)\.md$/
    assert PhoenixPages.wildcard_to_regex("foo/*/bar/*.md") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.md$/
    assert PhoenixPages.wildcard_to_regex("foo/**/bar/*.md") == ~r/foo\/(.*?)\/?bar\/([^.\/]*)\.md$/
    assert PhoenixPages.wildcard_to_regex("foo/*/bar/*.?d") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\..d$/
    assert PhoenixPages.wildcard_to_regex("foo/*/bar/*.??") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\...$/
    assert PhoenixPages.wildcard_to_regex("foo/*/bar/*.{md,me}") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.(?:md|me)$/
    assert PhoenixPages.wildcard_to_regex("foo/*/bar/*.m[d,e]") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.m[d,e]$/
    assert PhoenixPages.wildcard_to_regex("foo/*/bar/*.[a-z]d") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.[a-z]d$/
    assert PhoenixPages.wildcard_to_regex("foo/*/bar/*.[a-z,A-Z]") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.[a-z,A-Z]$/
    assert PhoenixPages.wildcard_to_regex("foo/**/*.{md,me}") == ~r/foo\/(.*?)\/?([^.\/]*)\.(?:md|me)$/
    assert PhoenixPages.wildcard_to_regex("foo/*/{bar,baz}/*.md") == ~r/foo\/([^.\/]*)\/(?:bar|baz)\/([^.\/]*)\.md$/
    assert PhoenixPages.wildcard_to_regex("foo/{bar,baz}/*.{md,me}") == ~r/foo\/(?:bar|baz)\/([^.\/]*)\.(?:md|me)$/
    assert PhoenixPages.wildcard_to_regex("foo/{bar,baz}/*.m[d,e]") == ~r/foo\/(?:bar|baz)\/([^.\/]*)\.m[d,e]$/
  end

  describe "cast_data/2" do
    test "should cast a list of required fields" do
      assert PhoenixPages.cast_data(%{content: "", foo: "bar"}, [:foo]) == %{content: "", foo: "bar"}
      assert PhoenixPages.cast_data(%{content: "", foo: ["bar"]}, [:foo]) == %{content: "", foo: ["bar"]}
    end

    test "should raise error if a required field is missing" do
      assert_raise KeyError, fn -> PhoenixPages.cast_data(%{content: ""}, [:foo]) end
    end

    test "should ignore non-cast fields" do
      assert PhoenixPages.cast_data(%{content: "", foo: "bar", baz: "qux"}, [:foo]) == %{content: "", foo: "bar"}
    end

    test "should add field defaults" do
      assert PhoenixPages.cast_data(%{content: ""}, foo: "bar") == %{content: "", foo: "bar"}

      assert PhoenixPages.cast_data(%{content: "", foo: "bar", baz: "baz"}, [:foo, baz: "qux"]) == %{
               content: "",
               foo: "bar",
               baz: "baz"
             }
    end
  end
end
