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

    rollup(opts)
  end

  def log(date, msg) do
    Logger.info "Rollup.GeoCountries.#{date} #{msg}"
  end

  def query(time) do
    BigQuery.Rollup.daily_geo_countries(time)
  end

  def upsert(results) do
    Castle.DailyGeoCountry.upsert_all(results)
  end
end
