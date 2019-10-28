defmodule Mix.Tasks.Castle.Rollup.LastWeekUniques do
  use Castle.Rollup.Task

  @shortdoc "Rollup uniques"

  @interval "singleton"
  @table "last_week_uniques"
  @lock "lock.rollup.last_week_uniques"
  @default_count 12

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    do_rollup(opts, &rollup/1)
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.LastWeekUniques.#{rollup_log.date} querying"

    meta = BigQuery.Rollup.last_week_uniques(rollup_log.date, fn(results) ->
      Logger.info "Rollup.LastWeekUniques.#{rollup_log.date} upserting #{length(results)}"
      Castle.LastWeekUnique.upsert_all(results)
    end)

    Logger.info "Rollup.LastWeekUniques.#{rollup_log.date} complete"
    set_complete(rollup_log)
  end
end
