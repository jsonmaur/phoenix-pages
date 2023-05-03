defmodule PhoenixPages.Helpers do
  @moduledoc false

  # Generates an MD5 hash of a sorted list.
  #
  # Returns a tuple with the first element being the sorted list, and the second element being the
  # hash. This is used to evaluate whether a list of files or dependencies have changed and should
  # force a recompilation.
  def hash(list) do
    hash =
      list
      |> Enum.map(&to_string/1)
      |> Enum.sort()
      |> :erlang.md5()

    {list, hash}
  end

  # Returns a list of files from a wildcard pattern and a hash of the filenames.
  def list_files(path, pattern) do
    path
    |> Path.join(pattern)
    |> Path.wildcard()
    |> hash()
  end

  # Returns a list of installed Makeup lexers and a hash of the names.
  def list_lexers do
    lexers =
      for {app, _, _} <- Application.loaded_applications(),
          match?("makeup_" <> _, Atom.to_string(app)),
          do: app

    hash(lexers)
  end

  # Generates a URL-safe slug from a path.
  #
  # Each chunk in the path will be trimmed of any leading/trailing whitespace, and any special
  # characters (excluding alphanumeric characters, dashes, and underscores) will be replaced with a
  # dash. Whitespace that is not leading or trailing will be replaced with dashes rather than
  # removed. Consecutive special characters will not be flattened, and will result in consecutive
  # dashes.
  def slugify(path) do
    ext = Path.extname(path)

    path
    |> Path.rootname()
    |> String.split("/")
    |> Enum.map(&String.trim(&1))
    |> Enum.map(&String.replace(&1, ~r/[^a-zA-Z0-9-_]/, "-"))
    |> Enum.join("/")
    |> Kernel.<>(ext)
  end

  # Converts a wildcard pattern into a regular expression.
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

  # Parses a filename into the `:page` segment and capture groups of a path.
  #
  # This works by converting the wildcard pattern used to list the file into a regular expression,
  # which is then used to extract the different groups of the filename. These groups are then
  # inserted into the path variables.
  #
  # The `:page` segment will always be a concatenation of all the capture groups. Use `$1`, `$2`,
  # etc. for individual capture groups. For example, a wildcard pattern of `priv/blog/**/*.md` will
  # create two capture groups:
  #
  #   - `$1` will contain whatever is captured with `**`
  #   - `$2` will contain whatever is captured with `*`
  #
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
