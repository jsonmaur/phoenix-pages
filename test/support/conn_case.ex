defmodule PhoenixPages.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint Router

      import PhoenixPages.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
