router =
  quote do
    use Phoenix.Router
    use PhoenixPages, otp_app: :phoenix_pages

    pages "/:page", unquote(Controller),
      from: "priv/pages/**/*.{md,markdown}",
      attrs: [lorem: "ipsum"],
      render_options: [markdown: [smartypants: false]],
      log: false

    pages "/blog/:page", unquote(Controller),
      id: :blog,
      from: "priv/blog/*.md",
      attrs: [:date],
      sort: {:date, :desc},
      assigns: %{foo: "bar"},
      log: false

    pages "/:page", unquote(Controller),
      from: "priv/pages/**/*.txt",
      log: false
  end

Module.create(Router, router, Macro.Env.location(__ENV__))
