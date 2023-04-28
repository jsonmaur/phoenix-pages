defmodule PhoenixPages.Markdown do
  @moduledoc false

  def render(contents, filename, opts) do
    escape_html = Keyword.get(opts, :escape_html, false)
    smartypants = Keyword.get(opts, :smartypants, true)
    compact_output = Keyword.get(opts, :compact_output, false)

    earmark_opts = %Earmark.Options{
      file: filename,
      escape: escape_html,
      smartypants: smartypants,
      compact_output: compact_output
    }

    contents
    |> Earmark.as_html!(earmark_opts)
    |> Phoenix.HTML.raw()
  end
end
