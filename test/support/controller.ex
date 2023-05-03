defmodule Controller do
  use Phoenix.Controller

  def show(conn, _), do: send_resp(conn, :ok, "")
end
