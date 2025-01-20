defmodule PhoenixPages.MarkdownTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import PhoenixPages.Markdown

  describe "render/3" do
    test "should render markdown with github flavored markdown" do
      assert render("~~foo~~", nil, []) == {:safe, "<p>\n<del>foo</del></p>\n"}

      assert render("foo|bar\n-|-\nbaz|qux", nil, []) ==
               {:safe,
                "<table>\n  <thead>\n    <tr>\n      <th style=\"text-align: left;\">\nfoo      </th>\n      <th style=\"text-align: left;\">\nbar      </th>\n    </tr>\n  </thead>\n  <tbody>\n    <tr>\n      <td style=\"text-align: left;\">\nbaz      </td>\n      <td style=\"text-align: left;\">\nqux      </td>\n    </tr>\n  </tbody>\n</table>\n"}
    end

    test "should render markdown with hard breaks" do
      md = "foo\nbar"

      assert render(md, nil, []) == {:safe, "<p>\nfoo\nbar</p>\n"}
      assert render(md, nil, hard_breaks: true) == {:safe, "<p>\nfoo  <br>\nbar</p>\n"}
    end

    test "should render markdown without wiki links" do
      md = "[[foo]]"

      assert render(md, nil, []) == {:safe, "<p>\n<a href=\"foo\">foo</a></p>\n"}
      assert render(md, nil, wiki_links: false) == {:safe, "<p>\n[[foo]]</p>\n"}
    end

    test "should render markdown without pure links" do
      md = "http://foo.com"

      assert render(md, nil, []) == {:safe, "<p>\n<a href=\"http://foo.com\">http://foo.com</a></p>\n"}
      assert render(md, nil, pure_links: false) == {:safe, "<p>\nhttp://foo.com</p>\n"}
    end

    test "should render markdown without sup sub" do
      md = "H~2~O"

      assert render(md, nil, []) == {:safe, "<p>\nH  <sub>\n2  </sub>\nO</p>\n"}
      assert render(md, nil, sub_sup: false) == {:safe, "<p>\nH~2~O</p>\n"}
    end

    test "should render markdown without footnotes" do
      md = "Hello[^foo]\n[^foo]: bar"

      assert render(md, nil, footnotes: false) == {:safe, "<p>\nHello[^foo]\n[^foo]: bar</p>\n"}

      assert render(md, nil, []) ==
               {:safe,
                "<p>\nHello<a href=\"#fn:foo\" id=\"fnref:foo\" class=\"footnote\" title=\"see footnote\">foo</a></p>\n<div class=\"footnotes\">\n  <hr>\n  <ol>\n    <li id=\"fn:foo\">\n<a title=\"return to article\" class=\"reversefootnote\" href=\"#fnref:foo\">&#x21A9;</a>      <p>\nbar      </p>\n    </li>\n  </ol>\n</div>\n"}
    end

    test "should render markdown with code class prefix" do
      md = "```json\n{}\n```"

      assert render(md, nil, syntax_highlighting: false) == {:safe, "<pre><code class=\"json\">{}</code></pre>\n"}

      assert render(md, nil, syntax_highlighting: false, code_class_prefix: "foo-") ==
               {:safe, "<pre><code class=\"json foo-json\">{}</code></pre>\n"}
    end

    test "should render markdown without smartypants" do
      md = "--"

      assert render(md, nil, []) == {:safe, "<p>\n–</p>\n"}
      assert render(md, nil, smartypants: false) == {:safe, "<p>\n--</p>\n"}
    end

    test "should render markdown with compact output" do
      md = "Hello"

      assert render(md, nil, []) == {:safe, "<p>\nHello</p>\n"}
      assert render(md, nil, compact_output: true) == {:safe, "<p>Hello</p>"}
    end

    test "should render markdown with escaped html" do
      md = "Hello <b>there</b>"

      assert render(md, nil, []) == {:safe, "<p>\nHello <b>there</b></p>\n"}
      assert render(md, nil, escape_html: true) == {:safe, "<p>\nHello &lt;b&gt;there&lt;/b&gt;</p>\n"}
    end

    test "should render markdown without syntax highlighting" do
      md = "```json\n{\"foo\": \"bar\"}\n```"

      assert render(md, nil, syntax_highlighting: false) ==
               {:safe, "<pre><code class=\"json\">{\"foo\": \"bar\"}</code></pre>\n"}

      assert {:safe, rendered} = render(md, nil, [])
      assert rendered =~ ~r/class="highlight json"/
      assert rendered =~ ~r/span class="p" data-group-id=".*"/
    end

    test "should log markdown error as warning" do
      assert capture_log(fn ->
               assert render("# Hello {:invalid}", "foo/bar.md", []) == {:safe, "<h1>\nHello</h1>\n"}
             end) =~ "foo/bar.md:1 Illegal attributes [\"invalid\"] ignored in IAL"
    end
  end
end
