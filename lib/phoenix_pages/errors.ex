defmodule PhoenixPages.NoPagesError do
  defexception [:id, :message]

  @impl true
  def exception(id: id) do
    %__MODULE__{message: "no pages found for id #{inspect(id)}"}
  end
end

defmodule PhoenixPages.ParseError do
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
