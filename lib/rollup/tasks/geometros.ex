defmodule Mix.Tasks.Castle.Rollup.Geometros do
  use Castle.Rollup.Task

  @shortdoc "Rollup bigquery geo metro codes by day"

  @table "daily_geo_metros"
  @lock "lock.rollup.geometros.vrmmm.vrmmmm"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    do_rollup(opts, &rollup/1)
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.DailyGeoMetro.#{rollup_log.date} querying"
    {results, meta} = rollup_log.date |> Timex.to_datetime() |> BigQuery.Rollup.daily_geo_metros()
    Logger.info "Rollup.DailyGeoMetro.#{rollup_log.date} upserting #{length(results)}"
    Castle.Repo.create_partition!(Castle.DailyGeoMetro, rollup_log.date)
    Castle.DailyGeoMetro.upsert_all(results)
    case meta do
      %{complete: true} ->
        set_complete(rollup_log)
        Logger.info "Rollup.DailyGeoMetro.#{rollup_log.date} complete"
      %{complete: false, hours_complete: h} ->
        set_incomplete(rollup_log)
        Logger.info "Rollup.DailyGeoMetro.#{rollup_log.date} incomplete (#{h}/24 hours)"
    end
  end
end
