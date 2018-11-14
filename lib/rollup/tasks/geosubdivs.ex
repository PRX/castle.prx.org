defmodule Mix.Tasks.Castle.Rollup.Geosubdivs do
  use Castle.Rollup.Task

  @shortdoc "Rollup bigquery geo iso subdivisions by day"

  @table "daily_geo_subdivs"
  @lock "lock.rollup.geosubdivs"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    rollup(opts)
  end

  def log(date, msg) do
    Logger.info "Rollup.GeoSubdivs.#{date} #{msg}"
  end

  def query(time) do
    BigQuery.Rollup.daily_geo_subdivs(time)
  end

  def upsert(results) do
    Castle.DailyGeoSubdiv.upsert_all(results)
  end
end
