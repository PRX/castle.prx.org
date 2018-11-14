defmodule Mix.Tasks.Castle.Rollup.Agents do
  use Castle.Rollup.Task

  @shortdoc "Rollup bigquery user agents by day"

  @table "daily_agents"
  @lock "lock.rollup.agents"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    rollup(opts)
  end

  def log(date, msg) do
    Logger.info "Rollup.Agents.#{date} #{msg}"
  end

  def query(time) do
    BigQuery.Rollup.daily_agents(time)
  end

  def upsert(results) do
    Castle.DailyAgent.upsert_all(results)
  end
end
