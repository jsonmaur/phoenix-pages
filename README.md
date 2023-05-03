<a href="https://github.com/jsonmaur/phoenix-pages/actions/workflows/test.yml"><img alt="Test Status" src="https://img.shields.io/github/actions/workflow/status/jsonmaur/phoenix-pages/test.yml?label=&style=for-the-badge&logo=github"></a> <a href="https://hexdocs.pm/phoenix_pages/"><img alt="Hex Version" src="https://img.shields.io/hexpm/v/phoenix_pages?style=for-the-badge&label=&logo=elixir" /></a>

Create blogs, documentation sites, and other static pages in Phoenix. This library integrates seamlessly into your router and comes with built-in support for rendering markdown with frontmatter, syntax highlighting, compile-time caching, and more.

## Getting Started

```elixir
def deps do
  [
    {:phoenix_pages, "~> 1.0"}
  ]
end
```

The recommended way to install into your Phoenix application is to add this to your `router` function in `lib/myapp_web.ex`, replacing `myapp` with the name of your application:

```elixir
def router do
  quote do
    use Phoenix.Router, helpers: false
    use PhoenixPages, otp_app: :myapp

    # ...
  end
end
```

Now you can add a new route using the [`pages/4`](https://hexdocs.pm/phoenix_pages/PhoenixPages.html#pages/4) macro:

```elixir
scope "/", MyAppWeb do
  pipe_through :browser

  get "/", PageController, :home
  pages "/:page", PageController, :show, from: "priv/pages/**/*.md"
end
```

This will read all the markdown files from `priv/pages` and create a new GET route for each one. The `:page` segment will be replaced with the path and filename (without the extension) relative to the base directory (see [Defining Paths](#defining-paths)).

You'll also need to add the `:show` handler to `lib/myapp_web/controllers/page_controller.ex`:

```elixir
defmodule MyAppWeb.PageController do
  use MyAppWeb, :controller

  # ...

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
```

Lastly, add a template at `lib/myapp_web/controllers/page_html/show.html.heex`. The page's rendered markdown will be available in the `inner_content` assign:

```heex
<main>
  <%= @inner_content %>
</main>
```

That's it! Now try creating a file at `priv/pages/hello.md` and visiting `/hello`.

## Frontmatter

Frontmatter allows page-specific variables to be included at the top of a markdown file using the YAML format. If you're setting frontmatter variables (which is optional), they must be the first thing in the file and must be set between triple-dashed lines:

```markdown
---
title: Hello World
---
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut
labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris
nisi ut aliquip ex ea commodo consequat.
```

To specify which frontmatter values are expected in each page, set the `attrs` option:

```elixir
pages "/:page", PageController, :show,
  from: "priv/pages/**/*.md",
  attrs: [:title, author: nil]
```

Atom values will be considered required, and a compilation error will be thrown if missing from any of the pages. Key-values must come last in the list, and will be considered optional by defining a default value. Any frontmatter values not defined in the attributes list will be silently discarded.

Valid attribute values will be available in the assigns:

```heex
<main>
  <h1><%= @title %></h1>
  <h2 :if={@author}><%= @author %></h2>

  <%= @inner_content %>
</main>
```

## Syntax Highlighting

Phoenix Pages uses the [Makeup](https://github.com/elixir-makeup/makeup) project for syntax highlighting. To enable, import a theme listed below into your CSS bundle. The specifics of doing this highly depend on your CSS configuration, but a few examples are included below. In most cases, you will need to import `phoenix_pages/css/monokai.css` (or whatever theme you choose) into your bundle and ensure `deps` is included as a vendor directory.

<details>
  <summary><b>Themes</b></summary>

  <ul>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#abap">abap</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#algol">algol</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#algol_nu">algol_nu</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#arduino">arduino</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#autumn">autumn</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#black_white">black_white</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#borland">borland</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#colorful">colorful</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#default">default</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#emacs">emacs</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#friendly">friendly</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#fruity">fruity</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#igor">igor</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#lovelace">lovelace</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#manni">manni</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#monokai">monokai</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#murphy">murphy</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#native">native</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#paraiso_dark">paraiso_dark</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#paraiso_light">paraiso_light</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#pastie">pastie</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#perldoc">perldoc</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#rainbow_dash">rainbow_dash</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#rrt">rrt</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#samba">samba</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#tango">tango</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#trac">trac</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#vim">vim</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#visual_studio">visual_studio</a></li>
    <li><a href="https://elixir-makeup.github.io/makeup_demo/elixir.html#xcode">xcode</a></li>
  </ul>
</details>

Next, add a Makeup lexer for your specific language(s) to the project dependencies. Phoenix Pages will pick up the new dependency and start highlighting your code blocks without any further configuration. No lexers are included by default.

<details>
  <summary><b>Lexers</b></summary>

  <ul>
    <li><a href="https://github.com/elixir-makeup/makeup_c">C</a> - <code>`{:makeup_c, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/elixir-makeup/makeup_diff">Diff</a> - <code>`{:makeup_diff, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/elixir-makeup/makeup_elixir">Elixir</a> - <code>`{:makeup_elixir, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/elixir-makeup/makeup_erlang">Erlang</a> - <code>`{:makeup_erlang, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/Billzabob/makeup_graphql">GraphQL</a> - <code>`{:makeup_graphql, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/elixir-makeup/makeup_eex">(H)EEx</a> - <code>`{:makeup_eex, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/elixir-makeup/makeup_html">HTML</a> - <code>`{:makeup_html, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/maartenvanvliet/makeup_js">Javascript</a> - <code>`{:makeup_js, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/elixir-makeup/makeup_json">JSON</a> - <code>`{:makeup_json, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/dottorblaster/makeup_rust">Rust</a> - <code>`{:makeup_rust, "~> 0.0"}`</code></li>
    <li><a href="https://github.com/Billzabob/makeup_sql">SQL</a> - <code>`{:makeup_sql, "~> 0.0"}`</code></li>
  </ul>
</details>

If your language of choice isn't supported, consider [writing a new Makeup lexer](https://github.com/elixir-makeup/makeup/blob/master/CONTRIBUTING.md#writing-a-new-lexer) to contribute to the community. Otherwise, you can use a JS-based syntax highlighter such as [highlight.js](https://highlightjs.org) by setting `code_class_prefix: "language-"` and `syntax_highlighting: false` in [`render_options`](https://hexdocs.pm/phoenix_pages/PhoenixPages.html#pages/4-options).

#### ESBuild Example

Using the [ESBuild installer](https://github.com/phoenixframework/esbuild), add the `env` option to `config/config.exs`:

```elixir
config :esbuild,
  version: "0.17.18",
  default: [
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)},
    args: ~w(--bundle --outdir=../priv/static/assets js/app.js)
  ]
```

Then in `app.js`:

```javascript
import "phoenix_pages/css/monokai.css";
```

#### SASS Example

Using the [Sass installer](https://github.com/CargoSense/dart_sass), add the `--load-path` flag to `config/config.exs`:

```elixir
config :dart_sass,
  version: "1.62.0",
  default: [
    cd: Path.expand("../assets", __DIR__),
    args: ~w(--load-path=../deps css/app.scss ../priv/static/assets/app.css)
  ]
```

Then in `app.scss`:

```sass
@import "phoenix_pages/css/monokai";
```

#### Tailwind Example

Install the `postcss-import` plugin as described [here](https://tailwindcss.com/docs/using-with-preprocessors#build-time-imports) and add the following to `assets/postcss.config.js`:

```javascript
module.exports = {
  plugins: {
    "postcss-import": {}
  }
}
```

Then in `app.css`:

```css
@import "../../deps/phoenix_pages/css/monokai";
```

## Index Pages

To create an index page with links to all the other pages, create a normal GET route and use the [`:id`](https://hexdocs.pm/phoenix_pages/PhoenixPages.html#pages/4-options) option alongside [`get_pages/1`](https://hexdocs.pm/phoenix_pages/PhoenixPages.html#c:get_pages/1) and [`get_pages!/1`](https://hexdocs.pm/phoenix_pages/PhoenixPages.html#c:get_pages!/1):

```elixir
get "/blog", BlogController, :index

pages "/blog/:page", BlogController, :show,
  id: :blog,
  from: "priv/blog/**/*.md",
  attrs: [:title, :author, :date]
```

```elixir
defmodule MyAppWeb.BlogController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    pages = MyAppWeb.Router.get_pages!(:blog)

    conn
    |> assign(:pages, pages)
    |> render("index.html")
  end

  def show(conn, _params) do
    render(conn, "show.html")
  end
end
```

```heex
<.link :for={page <- @pages} navigate={page.path}>
  <%= page.assigns.title %>
</.link>
```

You can take this even further by finding related pages, grouping by tags, etc.

### Sorting

The pages returned from the `get_pages` functions will be sorted by the filesystem's default sorting (usually by filename). If you want to specify a different sorting order during compilation rather than in the controller on every page load, use the [`:sort`](https://hexdocs.pm/phoenix_pages/PhoenixPages.html#pages/4-options) option:

```elixir
pages "/blog/:page", BlogController, :show,
  id: :blog,
  from: "priv/blog/**/*.md",
  attrs: [:title, :author, :date],
  sort: {:date, :desc}
```

Any attribute value from the frontmatter can be defined as the sort value.

## Defining Paths

When defining the pages path, the `:page` segment will get replaced for each generated page **during compilation** with the values derived from `**` and `*`. This is different than segments in regular routes, which are parsed **during runtime** into the `params` attribute of the controller function.

For example, let's say you have the following file structure:

```
├── priv/
│  ├── pages/
│  │  ├── foo.md
│  │  ├── bar/
│  │  │  ├── baz.md
```

Defining `pages "/:page", from: "priv/pages/**/*.md"` in your router will create two routes: `get "/foo"` and `get "/bar/baz"`. You can put the `:page` segment anywhere in the path, such as `/blog/:page`, and it will work as expected creating `get "/blog/foo"` and `get "/blog/bar/baz"`.

### Capture Groups

For complex scenarios, you have the option of using capture group variables instead of the `:page` segment.

Let's say you have the same file structure as above, but don't want the `baz` path to be nested under `/bar`. You could define `pages "/$2", from: "priv/pages/**/*.md"`, using `$2` instead of `:page`. This will create two routes: `get "/foo"` and `get "/bar"`.

Capture group variables will contain the value of the `**` and `*` chunks in order, starting at `$1`. Keep in mind that `**` will match all files and zero or more directories and subdirectories, and `*` will match any number of characters up to the end of the filename, the next dot, or the next slash.

For more info on the wildcard patterns, check out the documentation for [Path.wildcard/2](https://hexdocs.pm/elixir/1.13/Path.html#wildcard/2).

## Formatting

To prevent `mix format` from adding parenthesis to the `pages` macro similar to the other Phoenix Router macros, add `:phoenix_pages` to `.formatter.exs`:

```elixir
[
  import_deps: [:ecto, :ecto_sql, :phoenix, :phoenix_pages]
]
```

## Local Development

If you add, remove, or change pages while running `mix phx.server`, they will automatically be replaced in the cache and you don't have to restart for them to take effect. To live reload when a page changes, add `~r"priv/pages/.*(md)$"` to the patterns list of the Endpoint config in `config/dev.exs`.

## Extended Markdown

In addition to the customizable [markdown options](https://hexdocs.pm/phoenix_pages/PhoenixPages.html#pages/4-options), markdown rendering also supports IAL attributes by default. Meaning you can add HTML attributes to any block-level element using the syntax `{:attr}`.

For example, to create a rendered output of `<h1 class="foobar">Header</h1>`:

```markdown
# Header{:.foobar}
```

Attributes can be one of the following:

- `{:#id}` to define an ID
- `{:.className}` to define a class name
- `{:name=value}`, `{:name="value"}`, or `{:name='value'}` to define any other attribute

To define multiple attributes, separate them with spaces: `{:#id name=value}`.
