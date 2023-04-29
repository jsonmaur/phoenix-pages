defmodule PhoenixPages.NotFoundError do
  @moduledoc """
  Exception raised when `get_pages/1` or `get_pages!/1` is called with an ID that was not found.
  """

  defexception [:id, :message]

  @impl true
  def exception(id: id) do
    %__MODULE__{message: "no pages found for id #{inspect(id)}"}
  end
end

defmodule PhoenixPages.ParseError do
  @moduledoc """
  Exception raised when a page's frontmatter cannot be parsed.
  """

  defexception [:filename, :line, :column, :message]

  @impl true
  def exception(filename: filename, line: line, column: column) do
    %__MODULE__{message: "could not parse #{filename}:#{line}:#{column}"}
  end

  @impl true
  def exception(filename: filename) do
    %__MODULE__{message: "could not parse #{filename}"}
  end
end
