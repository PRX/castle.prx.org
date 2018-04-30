defmodule Mix.Tasks.Castle.Rollup.Downloads do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock

  @shortdoc "Rollup bigquery downloads by hour"

  @lock "lock.rollup.hourly_downloads"
  @table "hourly_downloads"
  @lock_ttl 50
  @success_ttl 10
  @default_limit 10

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    rollup_logs = cond do
      Enum.member?(args, "--date") ->
        [parse_date(args, "--date")]
      Enum.member?(args, "-d") ->
        [parse_date(args, "-d")]
      true ->
        Castle.RollupLog.find_missing(@table, @default_limit)
    end

    Enum.each rollup_logs, fn(log) ->
      if Enum.member?(args, "--lock") || Enum.member?(args, "-l") do
        lock "#{@lock}.#{log.date}", @lock_ttl, @success_ttl, do: rollup(log)
      else
        rollup(log)
      end
    end
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} querying"
    {results, meta} = rollup_log.date |> Timex.to_datetime() |> BigQuery.Rollup.daily_downloads()
    Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} upserting #{length(results)}"
    Castle.HourlyDownload.upsert_all(results)
    case meta do
      %{max_hour: 23} ->
        Castle.RollupLog.upsert(rollup_log)
        Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} complete"
      %{max_hour: hour} ->
        Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} incomplete (#{hour}/24 hours)"
    end
  end

  defp parse_date(args, key) when is_list(args) do
    index = Enum.with_index(args) |> Enum.into(%{}) |> Map.get(key)
    parse_date(Enum.at(args, index + 1))
  end
  defp parse_date(nil) do
    raise "You must provide a --date YYYYMMDD value"
  end
  defp parse_date(str) do
    format = case String.length(str) do
      10 -> "{YYYY}-{0M}-{0D}"
      8 -> "{YYYY}{0M}{0D}"
      _ -> "{ISO:Extended}"
    end
    case Timex.parse(str, format) do
      {:ok, dtim} -> %Castle.RollupLog{table_name: @table, date: Timex.to_date(dtim)}
      _ -> raise "Invalid date provided: #{str}"
    end
  end
end
