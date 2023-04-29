defmodule PhoenixPages.HighlightTest do
  use ExUnit.Case, async: true

  import PhoenixPages.Highlight

  describe "replace_node/1" do
    test "should add class to code tag" do
      assert replace_node({"code", [], [], []}) == {:replace, {"code", [{"class", "highlight"}], [], []}}
    end

    test "should not add class to inline code tag" do
      assert replace_node({"code", [{"class", "inline"}], [], []}) ==
               {:replace, {"code", [{"class", "inline"}], [], []}}
    end

    test "should change ast for code tag with supported language" do
      assert {:replace, {_, _, [ast], _}} = replace_node({"code", [{"class", "json"}], ["{}"], []})
      assert ast =~ ~r/span class="p" data-group-id=".*"/
    end

    test "should not change ast for code tag with unsupported language" do
      assert {:replace, {_, _, [ast], _}} = replace_node({"code", [{"class", "html"}], ["<div></div>"], []})
      assert ast == "<div></div>"
    end

    test "should not change ast for code tag with no language" do
      assert {:replace, {_, _, [ast], _}} = replace_node({"code", [], ["{}"], []})
      assert ast == "{}"
    end

    test "should not change ast for inline code tag" do
      assert {:replace, {_, _, [ast], _}} = replace_node({"code", [{"class", "inline"}], ["{}"], []})
      assert ast == "{}"
    end

    test "should ignore non-code tag" do
      assert replace_node({"p", [], [], []}) == {"p", [], [], []}
    end
  end
end
