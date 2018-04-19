defmodule Castle.Repo do
  use Ecto.Repo, otp_app: :castle

  def init(_, opts) do
    {:ok, load_opts(opts, Mix.env)}
  end

  defp load_opts(opts, env) when env in [:dev, :test] do
    Dotenv.load!
    load_opts(opts, nil)
  end
  defp load_opts(opts, _env) do
    opts
    |> Keyword.put(:database, Env.get(:pg_database))
    |> Keyword.put(:username, Env.get(:pg_user))
    |> Keyword.put(:password, Env.get(:pg_password))
    |> Keyword.put(:hostname, Env.get(:pg_host))
    |> Keyword.put(:port, Env.get(:pg_porth))
    |> Keyword.put(:pool_size, Env.get(:pg_pool_size))
  end
end
