defmodule Castle.RollupLog do
  use Ecto.Schema
  import Ecto.Changeset

  @buffer_seconds 300
  @beginning_of_time ~D[2017-04-01]
  def beginning_of_time, do: @beginning_of_time

  schema "rollup_logs" do
    field(:table_name, :string)
    field(:date, :date)
    field(:complete, :boolean, default: false)
    timestamps()
  end

  def changeset(rollup_log, attrs) do
    rollup_log
    |> cast(attrs, [:table_name, :date, :complete])
    |> validate_required([:table_name, :date, :complete])
  end

  def upsert!(log) do
    conflict = [set: [updated_at: Timex.now(), complete: log.complete]]
    target = [:table_name, :date]
    Castle.Repo.insert!(log, on_conflict: conflict, conflict_target: target)
  end

  def find_missing_days(tbl, lim), do: find_missing_days(tbl, lim, default_to_date())

  def find_missing_days(table_name, limit, to_date) do
    find_missing(table_name, limit, """
      SELECT r.DATE as date
      FROM GENERATE_SERIES('#{date_str(to_date)}', '#{@beginning_of_time}', '-1 DAY'::INTERVAL) r
    """)
  end

  def find_missing_weeks(tbl, lim), do: find_missing_weeks(tbl, lim, default_to_date())

  def find_missing_weeks(table_name, limit, to_date) do
    find_missing(table_name, limit, """
      SELECT r.DATE as date
      FROM GENERATE_SERIES('#{date_str(to_date, :week)}', '#{@beginning_of_time}', '-1 WEEK'::INTERVAL) r
    """)
  end

  def find_missing_months(tbl, lim), do: find_missing_months(tbl, lim, default_to_date())

  def find_missing_months(table_name, limit, to_date) do
    find_missing(table_name, limit, """
      SELECT r.DATE as date
      FROM GENERATE_SERIES('#{date_str(to_date, :month)}', '#{@beginning_of_time}', '-1 MONTH'::INTERVAL) r
    """)
  end

  defp find_missing(table_name, limit, range_sql) do
    query =
      """
      SELECT range.date FROM (#{range_sql}) as range
      WHERE range.date NOT IN
        (SELECT date FROM rollup_logs WHERE table_name = $1 AND complete = true)
      ORDER BY range.date DESC limit $2
      """
      |> String.replace("\n", " ")

    {:ok, result} = Ecto.Adapters.SQL.query(Castle.Repo, query, [table_name, limit])
    Enum.map(result.rows, &range_to_struct(table_name, hd(&1)))
  end

  defp range_to_struct(name, date) do
    %Castle.RollupLog{table_name: name, date: date}
  end

  defp default_to_date do
    Timex.now() |> Timex.shift(seconds: -@buffer_seconds)
  end

  defp date_str("" <> date, :month), do: date
  defp date_str(date, :month), do: Timex.beginning_of_month(date) |> date_str()
  defp date_str(date, :week), do: Timex.beginning_of_week(date, 7) |> date_str()
  defp date_str("" <> date), do: date

  defp date_str(date) do
    {:ok, date_str} = Timex.format(date, "{YYYY}-{0M}-{0D}")
    date_str
  end
end
