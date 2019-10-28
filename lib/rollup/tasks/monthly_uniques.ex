defmodule Mix.Tasks.Castle.Rollup.MonthlyUniques do
  use Castle.Rollup.Task

  @shortdoc "Rollup uniques"

  @interval "month"
  @table "monthly_uniques"
  @lock "lock.rollup.monthly_uniques"
  @default_count 12

  def run(args) do
    {:ok, _started} = Application.ensure_all_started(:castle)

    {opts, _, _} =
      OptionParser.parse(args,
        switches: [lock: :boolean, date: :string, count: :integer],
        aliases: [l: :lock, d: :date, c: :count]
      )

    do_rollup(opts, &rollup/1)
  end

  def rollup(rollup_log) do
    Logger.info("Rollup.MonthlyUniques.#{rollup_log.date} querying")

    %{total: total} =
      BigQuery.Rollup.monthly_uniques(rollup_log.date, fn results ->
        Logger.info("Rollup.MonthlyUniques.#{rollup_log.date} upserting #{length(results)}")
        Castle.MonthlyUnique.upsert_all(results)
      end)

    if is_past_month?(rollup_log.date) do
      set_complete(rollup_log)
      Logger.info("Rollup.MonthlyUniques.#{rollup_log.date} complete #{total}")
    else
      set_incomplete(rollup_log)
      Logger.info("Rollup.MonthlyUniques.#{rollup_log.date} incomplete #{total}")
    end
  end
end
