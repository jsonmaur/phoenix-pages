defmodule PhoenixPages do
  @moduledoc """
  Blogs, docs, and static pages in Phoenix. Check out the [README](readme.html) to get started.

  ## Options

    * `:otp_app` - The name of the OTP application to use as the base directory when looking for
    page files. This value is required.

    * `:render_options` - Allows the renderers to be configured. See `pages/4` for the options.

  """

  @type page :: PhoenixPages.Page.t()

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour PhoenixPages
      @before_compile PhoenixPages

      import PhoenixPages, only: [pages: 4]

      # find all the installed makeup lexers and starts them
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
          # recompile if a new makeup lexer dependency is added
          PhoenixPages.Helpers.list_lexers() |> elem(1) != @phoenix_pages_lexers_hash,

          # recompile if any pages were added or removed
          Enum.any?(@phoenix_pages_from, fn {from, hash} ->
            PhoenixPages.Helpers.list_files(@phoenix_pages_app_dir, from) |> elem(1) != hash
          end)
        ])
      end
    end
  end

  @doc """
  Finds all the pages matching a pattern and generates a GET route for each one.

  ## Options

    * `:id` - The ID for this collection of pages so they can later be accessed with
    [`get_pages/1`](PhoenixPages.html#c:get_pages/1) and [`get_pages!/1`](PhoenixPages.html#c:get_pages!/1).
    This is only required if using those functions.

    * `:from` - The [wildcard pattern](https://hexdocs.pm/elixir/1.13/Path.html#wildcard/2) used
    to look for pages on the filesystem. Make sure the base directory is included in your release
    (`priv` is included by default). Defaults to `priv/pages/**/*.md`.

    * `:sort` - The order of the pages returned when using `get_pages/1` and `get_pages!/1`.
    Defined as a tuple with the first element being an atom for the sort value (which can be any
    value from the attributes), and the second element being either `:asc` or `:desc`.

    * `:attrs` - A list of attributes used when parsing the markdown frontmatter for each page.
    Atoms will be required for each page, key values will be optional with a default value.
    Defaults to `[]`.

    * `:render_options` - Allows the renderers to be configured. This can also be set globally in
    the [module options](PhoenixPages.html#module-options).

      * `:markdown` - Allows the Earmark renderer to be configured.

        * `:hard_breaks` - Whether to convert hard line breaks to `<br>` tags. Defaults to `false`.
        * `:wiki_links` - Whether to enable wiki-style links such as `[[page]]`. Defaults to `true`.
        * `:pure_links` - Whether to convert raw URLs to `<a>` tags. Defaults to `true`.
        * `:sub_sup` - Whether to convert `~x~` and `^x^` to `<sub>` and `<sup>` tags. Defaults to `true`.
        * `:footnotes` - Whether to enable footnotes. Defaults to `true`.
        * `:smartypants` - Whether to enable [smartypants](https://daringfireball.net/projects/smartypants/). Defaults to `true`.
        * `:compact_output` - Whether to avoid indentation and minimize whitespace in output. Defaults to `false`.
        * `:escape_html` - Whether to allow raw HTML in markdown. Defaults to `false`.
        * `:syntax_highlighting` - Whether to enable Makeup syntax highlighting. Defaults to `true`.
        * `:code_class_prefix` - A class prefix to add to the language class of code blocks.

    * All other options are passed to [`Phoenix.Router.match/5`](https://hexdocs.pm/phoenix/Phoenix.Router.html#match/5-options)

  """
  defmacro pages(path, plug, plug_opts, opts \\ []) do
    quote bind_quoted: [path: path, plug: plug, plug_opts: plug_opts, opts: opts] do
      {id, opts} = Keyword.pop(opts, :id)
      {from, opts} = Keyword.pop(opts, :from, "priv/pages/**/*.md")
      {sort, opts} = Keyword.pop(opts, :sort)
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

      for page <- pages do
        opts = Keyword.put(opts, :assigns, page.assigns)
        Phoenix.Router.get(page.path, plug, plug_opts, opts)
      end

      @phoenix_pages PhoenixPages.sort(pages, sort)
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
  def sort(pages, {sort_by, sort_dir}) do
    Enum.sort_by(pages, &Map.get(&1.assigns, sort_by), sort_dir)
  end

  def sort(pages, _), do: pages

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

  @doc """
  Gets a list of pages for a given ID. See the `:id` option in `pages/4`.

  This can be used to get a list of pages from within a controller for index pages or further
  customization such as finding related pages, filtering by a value, etc. Returns `{:ok, pages}`
  if successful, or `:error` if no pages were defined with the ID.
  """
  @callback get_pages(id :: atom | binary) :: {:ok, list(page)} | :error

  @doc """
  Same as `get_pages/1`, but will raise `PhoenixPages.NotFoundError` if no pages were defined with
  the ID.
  """
  @callback get_pages!(id :: atom | binary) :: list(page)
end
