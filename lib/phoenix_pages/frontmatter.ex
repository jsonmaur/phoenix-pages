defmodule PhoenixPages.Frontmatter do
  @moduledoc false

  # Parses YAML frontmatter data out of a value.
  #
  # Returns a tuple with the first element being a map of the frontmatter data, and the second
  # element being the remaining body content. Raises `PhoenixPages.ParseError` if there is an error
  # parsing out the frontmatter.
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

  # Casts a map according to a list of attributes, similar to a struct.
  #
  # The attributes list must contain tuples for each value to cast, such as `[:val1, :val2]`.
  # Default values can be added at the end of the list with `[:val1, val2: "default"]`. Any value
  # without a default is required. Returns a new map with only the items defined in the attributes
  # list.
  def cast(data, attrs) when is_list(attrs) do
    Enum.into(attrs, %{}, fn v ->
      case v do
        {attr, default} -> {attr, Map.get(data, attr, default)}
        attr -> {attr, Map.fetch!(data, attr)}
      end
    end)
  end
end
