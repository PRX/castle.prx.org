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
    Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} querying"
    {results, meta} = rollup_log.date |> Timex.to_datetime() |> BigQuery.Rollup.hourly_downloads()
    Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} upserting #{length(results)}"
    Castle.Repo.create_partition!(Castle.HourlyDownload, rollup_log.date)
    Castle.HourlyDownload.upsert_all(results)
    case meta do
      %{complete: true} ->
        set_complete(rollup_log)
        Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} complete"
      %{complete: false, hours_complete: h} ->
        set_incomplete(rollup_log)
        Logger.info "Rollup.HourlyDownloads.#{rollup_log.date} incomplete (#{h}/24 hours)"
    end
  end
end
