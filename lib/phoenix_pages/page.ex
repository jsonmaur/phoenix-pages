defmodule PhoenixPages.Page do
  @enforce_keys [:path, :filename, :content]

  defstruct [:path, :filename, :content, assigns: %{}]

  @type t :: %__MODULE__{
          path: binary,
          filename: binary,
          content: binary,
          assigns: map
        }
end
