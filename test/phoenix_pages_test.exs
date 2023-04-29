defmodule PhoenixPagesTest do
  use PhoenixPages.ConnCase, async: true

  test "should add files to external resource list" do
    assert [[hello], [there], [post1], [post2], [yo]] =
             :attributes
             |> Router.__info__()
             |> Keyword.get_values(:external_resource)

    assert hello =~ "priv/pages/hello.md"
    assert there =~ "priv/pages/hello/there.markdown"
    assert post1 =~ "priv/blog/post1.md"
    assert post2 =~ "priv/blog/post2.md"
    assert yo =~ "priv/pages/yo.txt"
  end

  test "GET /hello", ctx do
    conn = get(ctx.conn, "/hello")

    assert response(conn, 200)
    assert conn.assigns.lorem == "dolor"
    assert conn.assigns.inner_content == {:safe, "<h1>\nHello</h1>\n"}
  end

  test "GET /hello/there", ctx do
    conn = get(ctx.conn, "/hello/there")

    assert response(conn, 200)
    assert conn.assigns.lorem == "ipsum"
    assert conn.assigns.inner_content == {:safe, "<h1>\nHello There...</h1>\n"}
  end

  test "GET /blog/post1", ctx do
    conn = get(ctx.conn, "/blog/post1")

    assert response(conn, 200)
    assert conn.assigns.foo == "bar"
    assert conn.assigns.inner_content == {:safe, "<h1>\nBlog Post 1</h1>\n"}
  end

  test "GET /blog/post2", ctx do
    conn = get(ctx.conn, "/blog/post2")

    assert response(conn, 200)
    assert conn.assigns.foo == "bar"
    assert conn.assigns.inner_content == {:safe, "<h1>\nBlog Post 2</h1>\n"}
  end

  test "GET /yo", ctx do
    conn = get(ctx.conn, "/yo")

    assert response(conn, 200)
    assert conn.assigns.inner_content == "Yo.\n"
  end

  describe "get_pages/1" do
    test "should return list of pages" do
      assert {:ok, [post2, post1]} = Router.get_pages(:blog)

      assert post1.path == "/blog/post1"
      assert post1.filename == "priv/blog/post1.md"
      assert post1.content == "# Blog Post 1\n"
      assert post1.assigns.foo == "bar"
      assert post1.assigns.inner_content == {:safe, "<h1>\nBlog Post 1</h1>\n"}

      assert post2.path == "/blog/post2"
      assert post2.filename == "priv/blog/post2.md"
      assert post2.content == "# Blog Post 2\n"
      assert post2.assigns.foo == "bar"
      assert post2.assigns.inner_content == {:safe, "<h1>\nBlog Post 2</h1>\n"}
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
      assert_raise PhoenixPages.NotFoundError, "no pages found for id :invalid", fn ->
        Router.get_pages!(:invalid)
      end
    end
  end
end
