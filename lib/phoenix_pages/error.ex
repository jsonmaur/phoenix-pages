defmodule PhoenixPages.Error do
  @moduledoc false

  defexception [:message]

  @impl true
  def exception(%{filename: filename, line: line, column: column}) do
    %__MODULE__{message: "could not parse #{filename}:#{line}:#{column}"}
  end

  @impl true
  def exception(%{filename: filename}) do
    %__MODULE__{message: "could not parse #{filename}"}
  end
end
