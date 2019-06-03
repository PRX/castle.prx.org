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

    do_rollup(opts, &rollup/1)
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.DailyAgent.#{rollup_log.date} querying"

    meta = BigQuery.Rollup.daily_agents(rollup_log.date, fn(results) ->
      Logger.info "Rollup.DailyAgent.#{rollup_log.date} upserting #{length(results)}"
      Castle.DailyAgent.upsert_all(results)
    end)

    case meta do
      %{complete: true, total: total} ->
        set_complete(rollup_log)
        Logger.info "Rollup.DailyAgent.#{rollup_log.date} complete #{total}"
      %{complete: false, total: total, hours_complete: h} ->
        set_incomplete(rollup_log)
        Logger.info "Rollup.DailyAgent.#{rollup_log.date} incomplete #{total} (#{h}/24 hours)"
    end
  end
end
