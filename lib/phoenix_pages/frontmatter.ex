defmodule PhoenixPages.Frontmatter do
  @moduledoc false

  def parse(contents, filename \\ nil) do
    with [fm, body] <- String.split(contents, ~r/\n---\n/, parts: 2),
         {:ok, %{} = data} <- String.trim(fm, "---") |> YamlElixir.read_from_string() do
      data
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), v} end)
      |> Map.put(:raw_content, body)
    else
      [body] ->
        %{raw_content: body}

      {:error, %YamlElixir.ParsingError{} = error} ->
        raise PhoenixPages.Error, message: "could not parse #{filename}:#{error.line}:#{error.column}"

      _ ->
        raise PhoenixPages.Error, message: "could not parse #{filename}"
    end
  end

  def cast(data, attrs) when is_list(attrs) do
    attrs = [:raw_content | attrs]

    Enum.into(attrs, %{}, fn v ->
      case v do
        {attr, default} -> {attr, Map.get(data, attr, default)}
        attr -> {attr, Map.fetch!(data, attr)}
      end
    end)
  end
end
