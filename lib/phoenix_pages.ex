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

          path = PhoenixPages.Helpers.into_path(path, file, from)
          filename = Path.relative_to(file, @phoenix_pages_app_dir)

          data =
            file
            |> File.read!()
            |> PhoenixPages.Frontmatter.parse(filename)
            |> PhoenixPages.Frontmatter.cast(attrs)
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
    case Path.extname(filename) do
      ext when ext in [".md", ".markdown"] ->
        markdown_opts = Keyword.get(opts, :markdown, [])
        inner_content = PhoenixPages.Markdown.render(data.raw_content, filename, markdown_opts)

        Map.put(data, :inner_content, inner_content)

      _ ->
        data
    end
  end
end
