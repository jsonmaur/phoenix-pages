defmodule PhoenixPages do
  @moduledoc """
  Blogs, docs, and static pages in Phoenix.
  Check out the [README](readme.html) to get started.
  """

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour PhoenixPages
      @before_compile PhoenixPages

      import PhoenixPages, only: [pages: 3]

      {lexers, lexers_hash} = PhoenixPages.Helpers.list_lexers()
      for lexer <- lexers, do: Application.ensure_all_started(lexer)

      @phoenix_pages_app_dir Keyword.fetch!(opts, :otp_app) |> Application.app_dir()
      @phoenix_pages_render_opts Keyword.get(opts, :render_options, [])
      @phoenix_pages_lexers_hash lexers_hash

      Module.register_attribute(__MODULE__, :phoenix_pages_from, accumulate: true)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl true
      def get_pages(id), do: :error

      @impl true
      def get_pages!(id) do
        raise PhoenixPages.NotFoundError, id: id
      end

      # this can screw things up in development (-_-)
      # if having problems with not recompiling for tests, run `MIX_ENV=test mix compile --force`
      def __mix_recompile__? do
        Enum.any?([
          PhoenixPages.Helpers.list_lexers() |> elem(1) != @phoenix_pages_lexers_hash,
          Enum.any?(@phoenix_pages_from, fn {from, hash} ->
            PhoenixPages.Helpers.list_files(@phoenix_pages_app_dir, from) |> elem(1) != hash
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
      {index_path, opts} = Keyword.pop(opts, :index_path)
      {attrs, opts} = Keyword.pop(opts, :attrs, [])
      {render_opts, opts} = Keyword.pop(opts, :render_options, @phoenix_pages_render_opts)
      {files, hash} = PhoenixPages.Helpers.list_files(@phoenix_pages_app_dir, from)

      assigns = Keyword.get(opts, :assigns, %{})

      pages =
        for file <- files do
          @external_resource file

          path = PhoenixPages.Helpers.into_path(path, file, from)
          filename = Path.relative_to(file, @phoenix_pages_app_dir)

          {data, content} = File.read!(file) |> PhoenixPages.Frontmatter.parse(filename)
          assigns = Map.merge(assigns, PhoenixPages.Frontmatter.cast(data, attrs))

          inner_content = PhoenixPages.render(content, filename, render_opts)
          assigns = Map.put(assigns, :inner_content, inner_content)

          struct!(PhoenixPages.Page,
            path: path,
            filename: filename,
            content: content,
            assigns: assigns
          )
        end

      if index_path do
        Phoenix.Router.get(index_path, plug, :index, opts)
      end

      for page <- pages do
        opts = Keyword.put(opts, :assigns, page.assigns)
        Phoenix.Router.get(page.path, plug, :show, opts)
      end

      @phoenix_pages pages
      @phoenix_pages_from {from, hash}

      if id do
        @impl true
        def get_pages(unquote_splicing([id])) do
          # the page id is guaranteed to exist, as it's being defined below
          {:ok, get_pages!(unquote(id))}
        end

        @impl true
        def get_pages!(unquote_splicing([id])) do
          @phoenix_pages
        end
      end
    end
  end

  @doc false
  def render(content, filename, opts) do
    case Path.extname(filename) do
      ext when ext in [".md", ".markdown"] ->
        markdown_opts = Keyword.get(opts, :markdown, [])
        PhoenixPages.Markdown.render(content, filename, markdown_opts)

      _ ->
        content
    end
  end

  @callback get_pages(atom | binary) :: {:ok, list(page)} | :error

  @callback get_pages!(atom | binary) :: list(page)
end
