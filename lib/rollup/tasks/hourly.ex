defmodule Mix.Tasks.Castle.Rollup.Hourly do
  use Castle.Rollup.Task

  @shortdoc "Rollup bigquery downloads by hour"

  @table "hourly_downloads"
  @lock "lock.rollup.hourly_downloads"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    do_rollup(opts, &rollup/1)
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.HourlyDownload.#{rollup_log.date} querying"

    meta = BigQuery.Rollup.hourly_downloads(rollup_log.date, fn(results) ->
      Logger.info "Rollup.HourlyDownload.#{rollup_log.date} upserting #{length(results)}"
      Castle.HourlyDownload.upsert_all(results)
    end)

    case meta do
      %{complete: true, total: total} ->
        set_complete(rollup_log)
        Logger.info "Rollup.HourlyDownload.#{rollup_log.date} complete #{total}"
      %{complete: false, total: total, hours_complete: h} ->
        set_incomplete(rollup_log)
        Logger.info "Rollup.HourlyDownload.#{rollup_log.date} incomplete #{total} (#{h}/24 hours)"
    end
  end
end
