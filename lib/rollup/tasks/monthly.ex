defmodule Mix.Tasks.Castle.Rollup.Monthly do
  use Castle.Rollup.Task

  @shortdoc "Rollup bigquery downloads by month"

  @interval "month"
  @table "monthly_downloads"
  @lock "lock.rollup.monthly_downloads"
  @default_count 10

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    rollup(opts)
  end

  def log(date, msg) do
    Logger.info "Rollup.MonthlyDownloads.#{date} #{msg}"
  end

  def query(time) do
    results = Castle.Rollup.Query.MonthlyDownloads.from_hourly(time)
    {results, %{complete: is_past_month?(time)}}
  end

  def upsert(results) do
    Castle.MonthlyDownload.upsert_all(results)
  end

  def is_past_month?(date, now \\ Timex.now) do
    offset = Timex.shift(now, months: -1, days: -1)
    Timex.compare(offset, date) > -1
  end
end
