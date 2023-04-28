defmodule PhoenixPages.Helpers do
  @moduledoc false

  def slugify(filename) do
    ext = Path.extname(filename)

    filename
    |> Path.rootname()
    |> String.split("/")
    |> Enum.map(&String.trim(&1))
    |> Enum.map(&String.replace(&1, ~r/[^a-zA-Z0-9-_]/, "-"))
    |> Enum.join("/")
    |> Kernel.<>(ext)
  end

  def wildcard_to_regex(pattern) do
    pattern
    |> Regex.escape()
    |> String.replace("\\?", ".")
    |> String.replace("\\[", "[")
    |> String.replace("\\]", "]")
    |> String.replace("\\{", "(?:")
    |> String.replace("\\}", ")")
    |> String.replace("\\*\\*/", "(.*?)\/?")
    |> String.replace("\\*\\*", "(.*?)\/?")
    |> String.replace("\\*", "([^./]*)")
    |> String.replace(~r/\(\?\:(.*?)\)/, &String.replace(&1, ",", "|"))
    |> String.replace(~r/\[(.*?)\]/, &String.replace(&1, "\\-", "-"))
    |> Kernel.<>("$")
    |> Regex.compile!()
  end

  def into_path(path, filename, pattern) do
    regex = wildcard_to_regex(pattern)
    slug = slugify(filename)

    case Regex.run(regex, slug) do
      nil ->
        raise ArgumentError, """
        Filename \"#{filename}\" does not match pattern \"#{pattern}\".
        Please open an issue for this: https://github.com/jsonmaur/phoenix-pages/issues
        """

      captures ->
        captures =
          captures
          |> Enum.with_index()
          |> Enum.map(fn {v, i} -> {"$#{i}", v} end)
          |> Enum.into(%{})

        page =
          captures
          |> Map.delete("$0")
          |> Map.values()
          |> Enum.filter(&(&1 != ""))
          |> Enum.map_join("/", &String.trim(&1, "/"))

        path
        |> String.replace(":page", page)
        |> String.replace(Map.keys(captures), &Map.get(captures, &1))
    end
  end
end
