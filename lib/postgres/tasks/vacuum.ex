defmodule Mix.Tasks.Postgres.Vacuum do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock

  @shortdoc "Run a full vacuum on postgres rollup tables"

  @lock "lock.postgres.vacuum"
  @lock_ttl 50
  @success_ttl 10

  # TODO: not sure why these are so different
  @daily_bloat_threshold 1.0
  @hourly_bloat_threshold 15.0

  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [lock: :boolean, table: :string],
        aliases: [l: :lock, t: :table]
      )

    if opts[:lock] do
      {:ok, _started} = Application.ensure_all_started(:castle)
    else
      Mix.Task.run("app.start")
    end

    tbl = opts[:table] || get_worst_table()

    if tbl do
      if opts[:lock] do
        lock(@lock, @lock_ttl, @success_ttl, do: full_vacuum(tbl))
      else
        full_vacuum(tbl)
      end
    end
  end

  defp get_worst_table do
    worst_daily = Postgres.Bloat.estimate("^daily.+_20[0-9]{4}", @daily_bloat_threshold)
    worst_hourly = Postgres.Bloat.estimate("^hourly.+_20[0-9]{4}", @hourly_bloat_threshold)

    case {worst_daily, worst_hourly} do
      {[tbl, _ratio], _} -> tbl
      {_, [tbl, _ratio]} -> tbl
      _ -> nil
    end
  end

  defp full_vacuum(tbl) do
    start = bloat_ratio(tbl)
    Logger.info("Postgres.Vacuum.#{tbl} starting (#{start} bloat ratio)")

    Castle.Repo.query!("VACUUM FULL #{tbl}", [], timeout: 300_000)

    complete = bloat_ratio(tbl)
    Logger.info("Postgres.Vacuum.#{tbl} complete (#{complete} bloat ratio)")

    if tbl =~ ~r/^daily/ && complete >= @daily_bloat_threshold do
      Logger.warn("Postgres.Vacuum.#{tbl} failed to fall below daily threshold")
    end

    if tbl =~ ~r/^hourly/ && complete >= @hourly_bloat_threshold do
      Logger.warn("Postgres.Vacuum.#{tbl} failed to fall below hourly threshold")
    end
  end

  defp bloat_ratio(tbl) do
    case Postgres.Bloat.estimate(tbl) do
      [_tbl, ratio] -> ratio
      _ -> 0
    end
  end
end
