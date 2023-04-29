defmodule PhoenixPagesTest do
  use ExUnit.Case, async: true

  import PhoenixPages
  import Phoenix.ConnTest

  @endpoint Router

  setup do
    %{conn: build_conn()}
  end

  test "should add files to external resource list" do
    assert [[hello], [there], [post1], [post2]] =
             :attributes
             |> Router.__info__()
             |> Keyword.get_values(:external_resource)

    assert hello =~ "priv/pages/hello.md"
    assert there =~ "priv/pages/hello/there.md"
    assert post1 =~ "priv/blog/post1.md"
    assert post2 =~ "priv/blog/post2.md"
  end

  test "GET /hello", ctx do
    conn = get(ctx.conn, "/hello")

    assert response(conn, 200)
    assert conn.assigns.lorem == "dolor"
    assert conn.assigns.path == "/hello"
    assert conn.assigns.filename == "priv/pages/hello.md"
    assert conn.assigns.raw_content == "# Hello\n"
    assert conn.assigns.inner_content == {:safe, "<h1>\nHello</h1>\n"}
  end

  test "GET /hello/there", ctx do
    conn = get(ctx.conn, "/hello/there")

    assert response(conn, 200)
    assert conn.assigns.lorem == "ipsum"
    assert conn.assigns.path == "/hello/there"
    assert conn.assigns.filename == "priv/pages/hello/there.md"
    assert conn.assigns.raw_content == "# Hello There...\n"
    assert conn.assigns.inner_content == {:safe, "<h1>\nHello There...</h1>\n"}
  end

  test "GET /blog", ctx do
    conn = get(ctx.conn, "/blog")

    assert response(conn, 200)
    assert conn.assigns.foo == "bar"
  end

  test "GET /blog/post1", ctx do
    conn = get(ctx.conn, "/blog/post1")

    assert response(conn, 200)
    assert conn.assigns.foo == "bar"
    assert conn.assigns.path == "/blog/post1"
    assert conn.assigns.filename == "priv/blog/post1.md"
    assert conn.assigns.raw_content == "# Blog Post 1\n"
    assert conn.assigns.inner_content == {:safe, "<h1>\nBlog Post 1</h1>\n"}
  end

  test "GET /blog/post2", ctx do
    conn = get(ctx.conn, "/blog/post2")

    assert response(conn, 200)
    assert conn.assigns.foo == "bar"
    assert conn.assigns.path == "/blog/post2"
    assert conn.assigns.filename == "priv/blog/post2.md"
    assert conn.assigns.raw_content == "# Blog Post 2\n"
    assert conn.assigns.inner_content == {:safe, "<h1>\nBlog Post 2</h1>\n"}
  end

  describe "get_pages/1" do
    test "should return list of pages" do
      assert {:ok, [post2, post1]} = Router.get_pages(:blog)
      assert post1.path == "/blog/post1"
      assert post2.path == "/blog/post2"
      assert post2.filename == "priv/blog/post2.md"
      assert post2.raw_content == "# Blog Post 2\n"
      assert post2.inner_content == {:safe, "<h1>\nBlog Post 2</h1>\n"}
    end

    test "should return error when called with invalid id" do
      assert Router.get_pages(:invalid) == :error
    end
  end

  describe "get_pages!/1" do
    test "should return list of pages" do
      assert [post2, post1] = Router.get_pages!(:blog)
      assert post1.path == "/blog/post1"
      assert post2.path == "/blog/post2"
    end

    test "should raise error when called with invalid id" do
      assert_raise PhoenixPages.Error, "no pages were defined with id: :invalid", fn ->
        Router.get_pages!(:invalid)
      end
    end
  end

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
