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

    meta = BigQuery.Rollup.daily_geo_metros(rollup_log.date, fn(results) ->
      Logger.info "Rollup.DailyGeoMetro.#{rollup_log.date} upserting #{length(results)}"
      Castle.DailyGeoMetro.upsert_all(results)
    end)

    case meta do
      %{complete: true, total: total} ->
        set_complete(rollup_log)
        Logger.info "Rollup.DailyGeoMetro.#{rollup_log.date} complete #{total}"
      %{complete: false, total: total, hours_complete: h} ->
        set_incomplete(rollup_log)
        Logger.info "Rollup.DailyGeoMetro.#{rollup_log.date} incomplete #{total} (#{h}/24 hours)"
    end
  end
end
