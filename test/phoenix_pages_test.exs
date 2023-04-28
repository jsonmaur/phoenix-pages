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
        md: %{raw_content: "# Hello"},
        txt: %{raw_content: "Hello"}
      }
    end

    test "should render a markdown file", ctx do
      assert PhoenixPages.render(ctx.md, "foobar.md", []).inner_content == {:safe, "<h1>\nHello</h1>\n"}
      assert PhoenixPages.render(ctx.md, "foobar.markdown", []).inner_content == {:safe, "<h1>\nHello</h1>\n"}
    end

    test "should render a markdown file with options", ctx do
      assert PhoenixPages.render(ctx.md, "foobar.md", markdown: [compact_output: true]).inner_content ==
               {:safe, "<h1>Hello</h1>"}
    end

    test "should render a raw text file", ctx do
      assert PhoenixPages.render(ctx.txt, "foobar.txt", []).raw_content == "Hello"
      refute PhoenixPages.render(ctx.txt, "foobar.txt", [])[:inner_content]
    end
  end
end
