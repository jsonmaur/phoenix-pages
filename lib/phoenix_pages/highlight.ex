defmodule PhoenixPages.Highlight do
  @moduledoc false

  alias Earmark.AstTools

  @css_class "highlight"
  @inner_html_tag "span"

  def replace_node({"code", attrs, ast, meta}) do
    lang = AstTools.find_att_in_node(attrs, "class", "") |> String.downcase()

    attrs =
      if lang == "inline" do
        attrs
      else
        AstTools.merge_atts(attrs, class: @css_class)
      end

    {:replace, {"code", attrs, process_ast(lang, ast), meta}}
  end

  def replace_node(node), do: node

  defp process_ast(lang, ast) when is_list(ast) do
    Enum.map(ast, &process_ast(lang, &1))
  end

  defp process_ast("", ast), do: ast
  defp process_ast("inline", ast), do: ast

  defp process_ast(lang, ast) do
    case get_lexer(lang) do
      nil ->
        ast

      {lexer, lexer_opts} ->
        Makeup.highlight_inner_html(ast,
          lexer: lexer,
          lexer_options: lexer_opts,
          formatter_options: [
            highlight_tag: @inner_html_tag
          ]
        )
    end
  end

  defp get_lexer(lang) do
    if lexer(lang) |> Code.ensure_loaded?() do
      Makeup.Registry.get_lexer_by_name(lang)
    end
  end

  defp lexer("html"), do: Makeup.Lexers.HTMLLexer
  defp lexer("eex"), do: Makeup.Lexers.EExLexer
  defp lexer("heex"), do: Makeup.Lexers.HEExLexer

  defp lexer(name) do
    "Elixir/Makeup/Lexers/#{name}_lexer"
    |> Macro.camelize()
    |> String.to_atom()
  end
end
