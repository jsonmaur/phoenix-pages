defmodule PhoenixPages.HelpersTest do
  use ExUnit.Case, async: true

  import PhoenixPages.Helpers

  test "hash/1" do
    assert hash(["b", "c", "a"]) ==
             {["b", "c", "a"], <<144, 1, 80, 152, 60, 210, 79, 176, 214, 150, 63, 125, 40, 225, 127, 114>>}
  end

  test "list_files/2" do
    path = Path.expand("../../priv/pages", __DIR__)

    assert {[file1, file2], hash} = list_files(path, "**/*.{md,markdown}")
    assert file1 =~ "priv/pages/hello.md"
    assert file2 =~ "priv/pages/hello/there.markdown"
    assert byte_size(hash) == 16
  end

  test "list_lexers/0" do
    assert {[:makeup_json], hash} = list_lexers()
    assert byte_size(hash) == 16
  end

  test "slugify/1" do
    assert slugify("foo.md") == "foo.md"
    assert slugify("foo/bar.md") == "foo/bar.md"
    assert slugify("/foo/bar.md") == "/foo/bar.md"
    assert slugify("/foo/b@r.md") == "/foo/b-r.md"
    assert slugify("/foo/ba@.md") == "/foo/ba-.md"
    assert slugify("/f&o/b@r.md") == "/f-o/b-r.md"
    assert slugify("/f_o/b_r.md") == "/f_o/b_r.md"
    assert slugify("/$oo/b@@.md") == "/-oo/b--.md"
    assert slugify("/foo/b-r.md") == "/foo/b-r.md"
    assert slugify("/foo/b--r.md") == "/foo/b--r.md"
    assert slugify("/foo/-bar-.md") == "/foo/-bar-.md"
    assert slugify("/foo/ bar .md") == "/foo/bar.md"
    assert slugify("/foo /bar.md") == "/foo/bar.md"
    assert slugify("/foo/b  a  r.md") == "/foo/b--a--r.md"
    assert slugify("/  foo  bar .md") == "/foo--bar.md"
    assert slugify("/  foo  /  bar .md") == "/foo/bar.md"
    assert slugify("/FOO_BAR.md") == "/FOO_BAR.md"
    assert slugify("/foo__bar.md") == "/foo__bar.md"
    assert slugify("/foo/bar$$baz.md") == "/foo/bar--baz.md"
    assert slugify("/foo/bar$$##baz.md") == "/foo/bar----baz.md"
    assert slugify("/foo/bar%123.md") == "/foo/bar-123.md"
    assert slugify("/foo.bar/baz.md") == "/foo-bar/baz.md"
    assert slugify("/foo/b@r/baz/") == "/foo/b-r/baz/"
  end

  test "wildcard_to_regex/1" do
    assert wildcard_to_regex("*") == ~r/([^.\/]*)$/
    assert wildcard_to_regex("*.md") == ~r/([^.\/]*)\.md$/
    assert wildcard_to_regex("**/*.md") == ~r/(.*?)\/?([^.\/]*)\.md$/
    assert wildcard_to_regex("foo/*.md") == ~r/foo\/([^.\/]*)\.md$/
    assert wildcard_to_regex("foo/**.md") == ~r/foo\/(.*?)\/?\.md$/
    assert wildcard_to_regex("foo/**/*.md") == ~r/foo\/(.*?)\/?([^.\/]*)\.md$/
    assert wildcard_to_regex("foo/*/bar/*.md") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.md$/
    assert wildcard_to_regex("foo/**/bar/*.md") == ~r/foo\/(.*?)\/?bar\/([^.\/]*)\.md$/
    assert wildcard_to_regex("foo/*/bar/*.?d") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\..d$/
    assert wildcard_to_regex("foo/*/bar/*.??") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\...$/
    assert wildcard_to_regex("foo/*/bar/*.{md,me}") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.(?:md|me)$/
    assert wildcard_to_regex("foo/*/bar/*.m[d,e]") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.m[d,e]$/
    assert wildcard_to_regex("foo/*/bar/*.[a-z]d") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.[a-z]d$/
    assert wildcard_to_regex("foo/*/bar/*.[a-z,A-Z]") == ~r/foo\/([^.\/]*)\/bar\/([^.\/]*)\.[a-z,A-Z]$/
    assert wildcard_to_regex("foo/**/*.{md,me}") == ~r/foo\/(.*?)\/?([^.\/]*)\.(?:md|me)$/
    assert wildcard_to_regex("foo/*/{bar,baz}/*.md") == ~r/foo\/([^.\/]*)\/(?:bar|baz)\/([^.\/]*)\.md$/
    assert wildcard_to_regex("foo/{bar,baz}/*.{md,me}") == ~r/foo\/(?:bar|baz)\/([^.\/]*)\.(?:md|me)$/
    assert wildcard_to_regex("foo/{bar,baz}/*.m[d,e]") == ~r/foo\/(?:bar|baz)\/([^.\/]*)\.m[d,e]$/
  end

  describe "into_path/3" do
    test "should put capture groups into page segment" do
      assert into_path(":page", "foo.md", "*.md") == "foo"
      assert into_path("/:page", "foo.md", "*.md") == "/foo"
      assert into_path("/:page", "/foo.md", "*.md") == "/foo"
      assert into_path("/:page/", "foo.md", "*.md") == "/foo/"
      assert into_path("/:page/bar", "foo.md", "*.md") == "/foo/bar"
      assert into_path("/foo:page", "bar.md", "*.md") == "/foobar"
      assert into_path("/:page/:page", "foo.md", "*.md") == "/foo/foo"
      assert into_path("/:page", "foo.md", "**/*.md") == "/foo"
      assert into_path("/:page", "foo/bar.md", "**/*.md") == "/foo/bar"
      assert into_path("/:page", "foo/bar.md", "foo/*.md") == "/bar"
      assert into_path("/:page", "foo/bar.md", "foo/**/*.md") == "/bar"
      assert into_path("/:page", "/foo/bar.md", "foo/**/*.md") == "/bar"
      assert into_path("/:page", "foo/bar/baz.md", "foo/**/*.md") == "/bar/baz"
      assert into_path("/:page", "foo/bar/baz/qux/quux.md", "foo/**/qux/*.md") == "/bar/baz/quux"
      assert into_path("/:page", "/foo/bar/baz/qux/quux.md", "foo/**/qux/*.md") == "/bar/baz/quux"
    end

    test "should put capture groups into variables" do
      assert into_path("$1", "foo.md", "*.md") == "foo"
      assert into_path("/$1", "foo.md", "*.md") == "/foo"
      assert into_path("/$1/", "foo.md", "*.md") == "/foo/"
      assert into_path("/$1/$1", "foo.md", "*.md") == "/foo/foo"
      assert into_path("/$1", "foo.md", "**.md") == "/foo"
      assert into_path("/foo$1", "bar.md", "**.md") == "/foobar"
      assert into_path("/$1", "foo/bar.md", "**.md") == "/foo/bar"
      assert into_path("/$1", "foo/bar.md", "**/*.md") == "/foo"
      assert into_path("/$1", "foo/bar/baz.md", "**/*.md") == "/foo/bar"
      assert into_path("/$2", "foo/bar/baz.md", "**/*.md") == "/baz"
      assert into_path("/$1/$2", "foo/bar.md", "foo/*.md") == "/bar/$2"
      assert into_path("/$1/$2", "foo/bar/baz/qux.md", "foo/*/baz/*.md") == "/bar/qux"
      assert into_path("/$2/$1", "foo/bar/baz/qux.md", "foo/*/baz/*.md") == "/qux/bar"
      assert into_path("/$1/$2/", "foo/bar/baz/qux.md", "foo/*/baz/*.md") == "/bar/qux/"
      assert into_path("/$1/$2", "foo/bar/baz/qux/quux.md", "foo/**/qux/*.md") == "/bar/baz/quux"
    end

    test "should put capture groups into out-of-order variables" do
      assert into_path("/$2/$1/$3", "foo/bar/baz/qux/quux.md", "**/*/qux/*.md") == "/baz/foo/bar/quux"
    end

    test "should put slugify each chunk of the path" do
      assert into_path("/:page", "foo@bar.md", "*.md") == "/foo-bar"
      assert into_path("/:page", "foo bar/baz@qux.md", "*.md") == "/baz-qux"
      assert into_path("/:page", "foo bar/baz@qux.md", "**/*.md") == "/foo-bar/baz-qux"
      assert into_path("/$1/$2", "foo bar/baz@qux.md", "**/*.md") == "/foo-bar/baz-qux"
    end

    test "should put capture groups into page segment and variables" do
      assert into_path("/:page/$2", "foo/bar/baz/qux.md", "foo/*/baz/*.md") == "/bar/qux/qux"
    end

    test "should raise error if filename does not match pattern" do
      assert_raise ArgumentError, fn -> into_path("/:page", "foo/bar.md", "baz/*.md") end
    end
  end
end
