defmodule Mix.Tasks.Castle.Rollup.WeeklyUniques do
  use Castle.Rollup.Task

  @shortdoc "Rollup uniques"

  @interval "week"
  @table "weekly_uniques"
  @lock "lock.rollup.weekly_uniques"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    do_rollup(opts, &rollup/1)
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.WeeklyUniques.#{rollup_log.date} querying"

    %{total: total} = BigQuery.Rollup.weekly_uniques(rollup_log.date, fn(results) ->
      Logger.info "Rollup.WeeklyUniques.#{rollup_log.date} upserting #{length(results)}"
      Castle.WeeklyUnique.upsert_all(results)
    end)

    if is_past_week?(rollup_log.date) do
      set_complete(rollup_log)
      Logger.info("Rollup.WeeklyUniques.#{rollup_log.date} complete #{total}")
    else
      set_incomplete(rollup_log)
      Logger.info("Rollup.WeeklyUniques.#{rollup_log.date} incomplete #{total}")
    end
  end

  def is_past_week?(date, now \\ Timex.now()) do
    offset = Timex.shift(now, weeks: -1, days: -1)
    Timex.compare(offset, date) > -1
  end
end
