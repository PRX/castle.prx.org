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

    rollup(opts)
  end

  def log(date, msg) do
    Logger.info "Rollup.GeoMetros.#{date} #{msg}"
  end

  def query(time) do
    BigQuery.Rollup.daily_geo_metros(time)
  end

  def upsert(results) do
    Castle.DailyGeoMetro.upsert_all(results)
  end
end
