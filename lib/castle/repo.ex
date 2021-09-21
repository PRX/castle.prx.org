defmodule Castle.Repo do
  use Ecto.Repo, otp_app: :castle, adapter: Ecto.Adapters.Postgres

  def init(_, opts) do
    {:ok, load_opts(opts)}
  end

  defp load_opts(opts) do
    opts
    |> Keyword.put_new(:database, Env.get(:pg_database))
    |> Keyword.put_new(:username, Env.get(:pg_user))
    |> Keyword.put_new(:password, Env.get(:pg_password))
    |> Keyword.put_new(:hostname, Env.get(:pg_host))
    |> Keyword.put_new(:port, Env.get(:pg_port))
    |> Keyword.put_new(:pool_size, Env.get(:pg_pool_size))
  end
end
