defmodule PhoenixPagesTest do
  use ExUnit.Case, async: true

  import PhoenixPages

  test "list_files/2" do
    path = Path.expand("../priv/pages", __DIR__)

    assert {[file1, file2], hash} = list_files(path, "**/*.md")
    assert file1 =~ "priv/pages/hello.md"
    assert file2 =~ "priv/pages/hello/there.md"
    assert byte_size(hash) == 16
  end

  test "list_lexers/0" do
    assert {[:makeup_json], hash} = list_lexers()
    assert byte_size(hash) == 16
  end

  describe "render/3" do
    test "should render a markdown file" do
      data = %{raw_content: "# Hello"}

      assert render(data, "foo.md", []).inner_content == {:safe, "<h1>\nHello</h1>\n"}
      assert render(data, "foo.markdown", []).inner_content == {:safe, "<h1>\nHello</h1>\n"}
    end

    test "should render a raw text file" do
      data = %{raw_content: "# Hello"}

      assert render(data, "foobar.txt", []).inner_content == "# Hello"
    end
  end
end
