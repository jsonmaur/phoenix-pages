defmodule PhoenixPages.Markdown do
  @moduledoc false

  alias Earmark.Transform

  require Logger

  # Renders markdown into HTML using Earmark and returns safe HTML.
  #
  # Uses highly opinionated markdown rendering options that can be customized. Also adds syntax
  # highlighting using Makeup unless it's disabled in the options.
  def render(contents, filename, opts) do
    hard_breaks = Keyword.get(opts, :hard_breaks, false)
    wiki_links = Keyword.get(opts, :wiki_links, true)
    pure_links = Keyword.get(opts, :pure_links, true)
    sub_sup = Keyword.get(opts, :sub_sup, true)
    footnotes = Keyword.get(opts, :footnotes, true)
    code_class_prefix = Keyword.get(opts, :code_class_prefix)
    smartypants = Keyword.get(opts, :smartypants, true)
    compact_output = Keyword.get(opts, :compact_output, false)
    escape_html = Keyword.get(opts, :escape_html, false)
    syntax_highlighting = Keyword.get(opts, :syntax_highlighting, true)

    parser_opts = [
      gfm: true,
      gfm_tables: true,
      file: filename,
      breaks: hard_breaks,
      sub_sup: sub_sup,
      wikilinks: wiki_links,
      pure_links: pure_links,
      footnotes: footnotes,
      code_class_prefix: code_class_prefix
    ]

    earmark_opts = %Earmark.Options{
      smartypants: smartypants,
      compact_output: compact_output,
      escape: escape_html
    }

    ast =
      case Earmark.Parser.as_ast(contents, parser_opts) do
        {:ok, ast, messages} ->
          log_messages(messages, filename)
          ast

        {:error, ast, messages} ->
          log_messages(messages, filename)
          ast
      end

    ast =
      if syntax_highlighting do
        Transform.map_ast(ast, &PhoenixPages.Highlight.replace_node/1)
      else
        ast
      end

    ast
    |> Transform.transform(earmark_opts)
    |> Phoenix.HTML.raw()
  end

  defp log_messages(messages, filename) do
    for {_, line, message} <- messages do
      Logger.warning("#{filename}:#{line} #{message}", [])
    end
  end
end
