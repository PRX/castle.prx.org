defmodule Mix.Tasks.Castle.Rollup.Geocountries do
  use Castle.Rollup.Task

  @shortdoc "Rollup bigquery geo iso countries by day"

  @table "daily_geo_countries"
  @lock "lock.rollup.geocountries"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    do_rollup(opts, &rollup/1)
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.DailyGeoCountry.#{rollup_log.date} querying"
    {results, meta} = rollup_log.date |> Timex.to_datetime() |> BigQuery.Rollup.daily_geo_countries()
    Logger.info "Rollup.DailyGeoCountry.#{rollup_log.date} upserting #{length(results)}"
    Castle.DailyGeoCountry.upsert_all(results)
    case meta do
      %{complete: true} ->
        set_complete(rollup_log)
        Logger.info "Rollup.DailyGeoCountry.#{rollup_log.date} complete"
      %{complete: false, hours_complete: h} ->
        set_incomplete(rollup_log)
        Logger.info "Rollup.DailyGeoCountry.#{rollup_log.date} incomplete (#{h}/24 hours)"
    end
  end
end
