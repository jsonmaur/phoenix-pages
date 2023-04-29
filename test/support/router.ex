router =
  quote do
    use Phoenix.Router
    use PhoenixPages, otp_app: :phoenix_pages

    pages "/:page", unquote(Controller),
      attrs: [lorem: "ipsum"],
      render_options: [markdown: [smartypants: false]],
      log: false

    pages "/blog/:page", unquote(Controller),
      id: :blog,
      from: "priv/blog/*.md",
      sort: {:path, :desc},
      assigns: %{foo: "bar"},
      index_path: "/blog",
      log: false
  end

Module.create(Router, router, Macro.Env.location(__ENV__))
