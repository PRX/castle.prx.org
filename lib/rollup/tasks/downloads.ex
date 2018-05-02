defmodule Mix.Tasks.Castle.Rollup.Downloads do
  use Mix.Task
  require Logger
  import Castle.Redis.Lock

  @shortdoc "Rollup bigquery downloads by hour"

  @lock "lock.rollup.hourly_downloads"
  @table "hourly_downloads"
  @lock_ttl 50
  @success_ttl 200
  @default_count 5

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    rollup_logs = case opts[:date] do
      nil ->
        Castle.RollupLog.find_missing(@table, opts[:count] || @default_count)
      date_str ->
        [%Castle.RollupLog{table_name: @table, date: parse_date(date_str)}]
    end

    Enum.each rollup_logs, fn(log) ->
      if opts[:lock] do
        lock "#{@lock}.#{log.date}", @lock_ttl, @success_ttl, do: rollup(log)
      else
        rollup(log)
      end
    end
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} querying"
    {results, meta} = rollup_log.date |> Timex.to_datetime() |> BigQuery.Rollup.hourly_downloads()
    Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} upserting #{length(results)}"
    Castle.HourlyDownload.upsert_all(results)
    case meta do
      %{complete: true} ->
        Castle.RollupLog.upsert(rollup_log)
        Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} complete"
      %{complete: false, hours_complete: h} ->
        Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} incomplete (#{h}/24 hours)"
    end
  end

  defp parse_date(str) do
    format = case String.length(str) do
      10 -> "{YYYY}-{0M}-{0D}"
      8 -> "{YYYY}{0M}{0D}"
      _ -> "{ISO:Extended}"
    end
    case Timex.parse(str, format) do
      {:ok, dtim} -> Timex.to_date(dtim)
      _ -> raise "Invalid date provided: #{str}"
    end
  end
end
