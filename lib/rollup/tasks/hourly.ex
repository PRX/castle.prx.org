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

    rollup(opts)
  end

  def log(date, msg) do
    Logger.info "Rollup.HourlyDownloads.#{date} #{msg}"
  end

  def query(time) do
    BigQuery.Rollup.hourly_downloads(time)
  end

  def upsert(results) do
    Castle.HourlyDownload.upsert_all(results)
  end
end
