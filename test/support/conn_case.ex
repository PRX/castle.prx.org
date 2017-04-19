defmodule Castle.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      import Castle.Router.Helpers

      # The default endpoint for testing
      @endpoint Castle.Endpoint
    end
  end

  setup tags do
    conn = Phoenix.ConnTest.build_conn() |> basic_auth(tags)
    {:ok, conn: conn}
  end

  defp basic_auth(conn, %{no_auth: true}), do: conn
  defp basic_auth(conn, _tags) do
    set_auth_header conn, Env.get(:basic_auth_user), Env.get(:basic_auth_pass)
  end

  defp set_auth_header(conn, nil, nil), do: conn
  defp set_auth_header(conn, user, pass) do
    Plug.Conn.put_req_header conn, "authorization", "Basic " <> Base.encode64("#{user}:#{pass}")
  end
end
