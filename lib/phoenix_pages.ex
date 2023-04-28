defmodule PhoenixPages do
  @moduledoc """
  Blogs, docs, and static pages in Phoenix.
  Check out the [README](readme.html) to get started.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      otp_app = Keyword.fetch!(opts, :otp_app)
      render_opts = Keyword.get(opts, :render_options, [])

      import PhoenixPages, only: [pages: 3]

      @before_compile PhoenixPages
      @phoenix_pages_app_dir Application.app_dir(otp_app)
      @phoenix_pages_render_opts render_opts

      Module.register_attribute(__MODULE__, :phoenix_pages, accumulate: true)
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def __mix_recompile__? do
        Enum.any?(@phoenix_pages, fn {from, hash} ->
          PhoenixPages.list_files(@phoenix_pages_app_dir, from) |> elem(1) != hash
        end)
      end
    end
  end

  @doc """
  """
  defmacro pages(path, plug, opts) do
    quote bind_quoted: [path: path, plug: plug, opts: opts] do
      {render_opts, opts} = Keyword.pop(opts, :render_options, @phoenix_pages_render_opts)
      {from, opts} = Keyword.pop(opts, :from, "priv/pages/**/*.md")
      {{sort_key, sort_dir}, opts} = Keyword.pop(opts, :sort, {:path, :asc})
      {index_path, opts} = Keyword.pop(opts, :index_path)
      {attrs, opts} = Keyword.pop(opts, :attrs, [])
      {assigns, opts} = Keyword.pop(opts, :assigns, %{})
      {files, hash} = PhoenixPages.list_files(@phoenix_pages_app_dir, from)

      @phoenix_pages {from, hash}

      pages =
        for file <- files do
          @external_resource file

          path = PhoenixPages.into_path(path, file, from)
          filename = Path.relative_to(file, @phoenix_pages_app_dir)

          data =
            file
            |> File.read!()
            |> PhoenixPages.parse_frontmatter(filename)
            |> PhoenixPages.cast_data(attrs)
            |> PhoenixPages.render(filename, render_opts)

          Map.merge(%{path: path, filename: filename}, data)
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
    markdown_opts = Keyword.get(opts, :markdown, [])

    case Path.extname(filename) do
      ext when ext in [".md", ".markdown"] ->
        escape_html = Keyword.get(markdown_opts, :escape_html, false)
        smartypants = Keyword.get(markdown_opts, :smartypants, true)
        compact_output = Keyword.get(markdown_opts, :compact_output, false)

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
    with [fm, body] <- String.split(content, ~r/\n---\n/, parts: 2),
         {:ok, %{} = data} <- String.trim(fm, "---") |> YamlElixir.read_from_string() do
      data
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Map.put(:content, body)
    else
      [body] ->
        %{content: body}

      {:error, %YamlElixir.ParsingError{} = error} ->
        raise PhoenixPages.ParseError, %{filename: filename, line: error.line, column: error.column}

      _ ->
        raise PhoenixPages.ParseError, %{filename: filename}
    end
  end

  @doc false
  def slugify(filename) do
    ext = Path.extname(filename)

    filename
    |> Path.rootname()
    |> String.split("/")
    |> Enum.map(&String.trim(&1))
    |> Enum.map(&String.replace(&1, ~r/[^a-zA-Z0-9-_]/, "-"))
    |> Enum.join("/")
    |> Kernel.<>(ext)
  end

  @doc false
  def into_path(path, filename, pattern) do
    regex = wildcard_to_regex(pattern)
    slug = slugify(filename)

    case Regex.run(regex, slug) do
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
