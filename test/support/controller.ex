defmodule Controller do
  use Phoenix.Controller

  def index(conn, _), do: send_resp(conn, :ok, "")
  def show(conn, _), do: send_resp(conn, :ok, "")
end
