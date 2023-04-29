defmodule PhoenixPages do
  @moduledoc """
  Blogs, docs, and static pages in Phoenix.
  Check out the [README](readme.html) to get started.
  """

  defmodule Error do
    defexception [:message]
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @before_compile PhoenixPages

      import PhoenixPages, only: [pages: 3]

      {lexers, lexers_hash} = PhoenixPages.list_lexers()
      for lexer <- lexers, do: Application.ensure_all_started(lexer)

      @phoenix_pages_app_dir Keyword.fetch!(opts, :otp_app) |> Application.app_dir()
      @phoenix_pages_render_opts Keyword.get(opts, :render_options, [])
      @phoenix_pages_lexers_hash lexers_hash

      Module.register_attribute(__MODULE__, :phoenix_pages_from, accumulate: true)
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      def get_pages(id), do: :error

      def get_pages!(id) do
        raise Error, "no pages were defined with id: #{inspect(id)}"
      end

      def __mix_recompile__? do
        Enum.any?([
          PhoenixPages.list_lexers() |> elem(1) != @phoenix_pages_lexers_hash,
          Enum.any?(@phoenix_pages_from, fn {from, hash} ->
            PhoenixPages.list_files(@phoenix_pages_app_dir, from) |> elem(1) != hash
          end)
        ])
      end
    end
  end

  @doc """
  """
  defmacro pages(path, plug, opts \\ []) do
    quote bind_quoted: [path: path, plug: plug, opts: opts] do
      {id, opts} = Keyword.pop(opts, :id)
      {from, opts} = Keyword.pop(opts, :from, "priv/pages/**/*.md")
      {{sort_key, sort_dir}, opts} = Keyword.pop(opts, :sort, {:path, :asc})
      {index_path, opts} = Keyword.pop(opts, :index_path)
      {attrs, opts} = Keyword.pop(opts, :attrs, [])
      {render_opts, opts} = Keyword.pop(opts, :render_options, @phoenix_pages_render_opts)

      {files, hash} = PhoenixPages.list_files(@phoenix_pages_app_dir, from)

      pages =
        for file <- files do
          @external_resource file

          path = PhoenixPages.Helpers.into_path(path, file, from)
          filename = Path.relative_to(file, @phoenix_pages_app_dir)

          file
          |> File.read!()
          |> PhoenixPages.Frontmatter.parse(filename)
          |> PhoenixPages.Frontmatter.cast(attrs)
          |> PhoenixPages.render(filename, render_opts)
          |> Map.merge(%{path: path, filename: filename})
        end
        |> Enum.sort_by(&Map.get(&1, sort_key), sort_dir)

      @phoenix_pages pages
      @phoenix_pages_from {from, hash}

      if index_path do
        Phoenix.Router.get(index_path, plug, :index, opts)
      end

      for page <- pages do
        assigns = Keyword.get(opts, :assigns, %{})
        opts = Keyword.put(opts, :assigns, Map.merge(assigns, page))

        Phoenix.Router.get(page.path, plug, :show, opts)
      end

      if id do
        def get_pages!(unquote_splicing([id])), do: @phoenix_pages
        def get_pages(unquote_splicing([id])), do: {:ok, get_pages!(unquote(id))}
      end
    end
  end

  @doc false
  def list_files(path, pattern) do
    path
    |> Path.join(pattern)
    |> Path.wildcard()
    |> PhoenixPages.Helpers.hash()
  end

  @doc false
  def list_lexers do
    lexers =
      for {app, _, _} <- Application.loaded_applications(),
          match?("makeup_" <> _, Atom.to_string(app)),
          do: app

    PhoenixPages.Helpers.hash(lexers)
  end

  @doc false
  def render(data, filename, opts) do
    inner_content =
      case Path.extname(filename) do
        ext when ext in [".md", ".markdown"] ->
          markdown_opts = Keyword.get(opts, :markdown, [])
          PhoenixPages.Markdown.render(data.raw_content, filename, markdown_opts)

        _ ->
          data.raw_content
      end

    Map.put(data, :inner_content, inner_content)
  end
end
