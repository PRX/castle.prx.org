defmodule Castle.Repo do
  use Ecto.Repo, otp_app: :castle

  def init(_, opts) do
    {:ok, load_opts(opts, Mix.env)}
  end

  def create_partition!(mod, date) do
    table = Ecto.get_meta struct(mod), :source
    start = Timex.beginning_of_month(date)
    stop = Timex.shift(start, months: 1)
    {:ok, part_str} = Timex.format(date, "{YYYY}{0M}")
    {:ok, start_str} = Timex.format(start, "{YYYY}-{0M}-{0D}")
    {:ok, stop_str} = Timex.format(stop, "{YYYY}-{0M}-{0D}")
    Ecto.Adapters.SQL.query! Castle.Repo, """
      CREATE TABLE IF NOT EXISTS #{table}_#{part_str}
      PARTITION OF #{table}
      FOR VALUES FROM ('#{start_str}') TO ('#{stop_str}');
    """
  end

  defp load_opts(opts, env) when env in [:dev, :test] do
    Dotenv.load!
    load_opts(opts, nil)
  end
  defp load_opts(opts, _env) do
    opts
    |> Keyword.put(:database, database())
    |> Keyword.put(:username, Env.get(:pg_user))
    |> Keyword.put(:password, Env.get(:pg_password))
    |> Keyword.put(:hostname, Env.get(:pg_host))
    |> Keyword.put(:port, Env.get(:pg_port))
    |> Keyword.put(:pool_size, Env.get(:pg_pool_size))
  end

  defp database() do
    case Mix.env do
      :test -> "castle_test"
      _ -> Env.get(:pg_database)
    end
  end
end
