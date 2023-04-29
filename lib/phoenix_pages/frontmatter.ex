defmodule PhoenixPages.Frontmatter do
  @moduledoc false

  def parse(contents, filename \\ nil) do
    with [fm, content] <- String.split(contents, ~r/\n---\n/, parts: 2),
         {:ok, %{} = data} <- String.trim(fm, "---") |> YamlElixir.read_from_string() do
      data =
        Enum.into(data, %{}, fn {k, v} ->
          {String.to_existing_atom(k), v}
        end)

      {data, content}
    else
      [content] ->
        {%{}, content}

      {:error, %YamlElixir.ParsingError{} = error} ->
        raise PhoenixPages.ParseError, filename: filename, line: error.line, column: error.column

      _ ->
        raise PhoenixPages.ParseError, filename: filename
    end
  end


  def cast(data, attrs) when is_list(attrs) do
    Enum.into(attrs, %{}, fn v ->
      case v do
        {attr, default} -> {attr, Map.get(data, attr, default)}
        attr -> {attr, Map.fetch!(data, attr)}
      end
    end)
  end
end
