defmodule Mix.Tasks.Castle.Rollup.Last28Uniques do
  use Castle.Rollup.Task

  @shortdoc "Rollup uniques"

  @interval "day"
  @table "last_28_uniques"
  @lock "lock.rollup.last_28_uniques"

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} = OptionParser.parse args,
      switches: [lock: :boolean, date: :string, count: :integer],
      aliases: [l: :lock, d: :date, c: :count]

    do_rollup(opts, &rollup/1)
  end

  def rollup(rollup_log) do
    Logger.info "Rollup.Last28Uniques.#{rollup_log.date} querying"

    BigQuery.Rollup.last_28_uniques(rollup_log.date, fn(results) ->
      Logger.info "Rollup.Last28Uniques.#{rollup_log.date} upserting #{length(results)}"
      Castle.Last28Unique.upsert_all(results)
    end)

    Logger.info "Rollup.Last28Uniques.#{rollup_log.date} complete"
    set_complete(rollup_log)
  end
end
