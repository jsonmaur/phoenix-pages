defmodule PhoenixPages do
  @moduledoc false

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)
      from = Keyword.get(opts, :from, "priv/pages")
      markdown = Keyword.get(opts, :markdown, [])

      import PhoenixPages, only: [pages: 3]

      @before_compile PhoenixPages
      @phoenix_pages_from Application.app_dir(otp_app, from)
      @phoenix_pages_markdown markdown

      Module.register_attribute(__MODULE__, :phoenix_pages, accumulate: true)
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def __mix_recompile__? do
        Enum.any?(@phoenix_pages, fn {from, hash} ->
          PhoenixPages.list_files(@phoenix_pages_from, from) |> elem(1) != hash
        end)
      end
    end
  end

  @doc """
  """
  defmacro pages(path, plug, opts) do
    quote bind_quoted: [path: path, plug: plug, opts: opts] do
      {from, opts} = Keyword.pop(opts, :from, "**/*.md")
      {attrs, opts} = Keyword.pop(opts, :attrs, [])
      {{sort_key, sort_dir}, opts} = Keyword.pop(opts, :sort, {:slug, :asc})
      {index_path, opts} = Keyword.pop(opts, :index_path)
      {assigns, opts} = Keyword.pop(opts, :assigns, %{})
      {files, hash} = PhoenixPages.list_files(@phoenix_pages_from, from)

      @phoenix_pages {from, hash}

      pages =
        for file <- files do
          @external_resource file

          path = PhoenixPages.filename_into_path(path, file, from)
          slug = PhoenixPages.filename_to_slug(file)
          filename = Path.relative_to(file, @phoenix_pages_from)

          data =
            file
            |> File.read!()
            |> PhoenixPages.parse_frontmatter(filename)
            |> PhoenixPages.cast_data(attrs)
            |> PhoenixPages.render(filename, @phoenix_pages_markdown)

          Map.merge(%{path: path, slug: slug, filename: filename}, data)
        end
        |> Enum.sort_by(&Map.get(&1, sort_key), sort_dir)

      assigns = Map.merge(assigns, %{pages: pages})
      opts = Keyword.put(opts, :assigns, assigns)

      if index_path do
        Phoenix.Router.get(index_path, plug, :index, opts)
      end

      for page <- pages do
        opts = Keyword.put(opts, :assigns, Map.merge(opts[:assigns], page))

        Phoenix.Router.get(page.path, plug, :show, opts)
      end
    end
  end

  @doc false
  def list_files(path, pattern) do
    files =
      path
      |> Path.join(pattern)
      |> Path.wildcard()
      |> Enum.sort()

    {files, :erlang.md5(files)}
  end

  @doc false
  def render(data, filename, opts) do
    case Path.extname(filename) do
      ext when ext in [".md", ".markdown"] ->
        escape_html = Keyword.get(opts, :escape_html, false)
        smartypants = Keyword.get(opts, :smartypants, true)
        compact_output = Keyword.get(opts, :compact_output, false)

        earmark_opts = %Earmark.Options{
          file: filename,
          escape: escape_html,
          smartypants: smartypants,
          compact_output: compact_output
        }

        inner_content =
          data.content
          |> Earmark.as_html!(earmark_opts)
          |> Phoenix.HTML.raw()

        Map.put(data, :inner_content, inner_content)

      _ ->
        data
    end
  end

  @doc false
  def parse_frontmatter(content, filename \\ nil) do
    with [frontmatter, content] <- String.split(content, ~r/\n---\n/, parts: 2),
         {:ok, %{} = data} <- String.trim(frontmatter, "---") |> YamlElixir.read_from_string() do
      data
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Map.put(:content, content)
    else
      [content] ->
        %{content: content}

      {:error, %YamlElixir.ParsingError{} = error} ->
        raise PhoenixPages.ParseError, %{filename: filename, line: error.line, column: error.column}

      _ ->
        raise PhoenixPages.ParseError, %{filename: filename}
    end
  end

  @doc false
  def filename_to_slug(filename) do
    filename
    |> Path.basename()
    |> Path.rootname()
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/[^a-zA-Z0-9-]+/, "-")
  end

  @doc false
  def filename_into_path(path, filename, pattern) do
    case wildcard_to_regex(pattern) |> Regex.run(filename) do
      nil ->
        raise ArgumentError, """
        Filename \"#{filename}\" does not match pattern \"#{pattern}\".
        Please open an issue for this: https://github.com/jsonmaur/phoenix-pages/issues
        """

      captures ->
        captures =
          captures
          |> Enum.with_index()
          |> Enum.map(fn {v, i} -> {"$#{i}", v} end)
          |> Enum.into(%{})

        page =
          captures
          |> Map.delete("$0")
          |> Map.values()
          |> Enum.filter(&(&1 != ""))
          |> Enum.map_join("/", &String.trim(&1, "/"))

        path
        |> String.replace(":page", page)
        |> String.replace(Map.keys(captures), &Map.get(captures, &1))
    end
  end

  @doc false
  def wildcard_to_regex(pattern) do
    pattern
    |> Regex.escape()
    |> String.replace("\\?", ".")
    |> String.replace("\\[", "[")
    |> String.replace("\\]", "]")
    |> String.replace("\\{", "(?:")
    |> String.replace("\\}", ")")
    |> String.replace("\\*\\*/", "(.*?)\/?")
    |> String.replace("\\*\\*", "(.*?)\/?")
    |> String.replace("\\*", "([^./]*)")
    |> String.replace(~r/\(\?\:(.*?)\)/, &String.replace(&1, ",", "|"))
    |> String.replace(~r/\[(.*?)\]/, &String.replace(&1, "\\-", "-"))
    |> Kernel.<>("$")
    |> Regex.compile!()
  end

  @doc false
  def cast_data(data, attrs) when is_list(attrs) do
    attrs = [:content | attrs]

    Enum.into(attrs, %{}, fn v ->
      case v do
        {attr, default} -> {attr, Map.get(data, attr, default)}
        attr -> {attr, Map.fetch!(data, attr)}
      end
    end)
  end
end
