defmodule PhoenixPages.MixProject do
  use Mix.Project

  @url "https://github.com/jsonmaur/phoenix-pages"

  def project do
    [
      app: :phoenix_pages,
      version: "1.0.0",
      elixir: "~> 1.13",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      source_url: @url,
      homepage_url: "#{@url}#readme",
      description: "",
      authors: ["Jason Maurer"],
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => @url},
        files: ~w(css lib .formatter.exs CHANGELOG.md LICENSE mix.exs README.md)
      ],
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:earmark, "~> 1.4"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:makeup, "~> 1.0"},
      {:makeup_json, "~> 0.1.0", only: :test},
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.3"},
      {:yaml_elixir, "~> 2.9"}
    ]
  end

  defp aliases do
    [
      test: [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "test"
      ]
    ]
  end
end
