defmodule Castle.RollupLog do
  use Ecto.Schema
  import Ecto.Changeset

  @beginning_of_time "2017-04-07"
  @buffer_seconds 300

  schema "rollup_logs" do
    field :table_name, :string
    field :date, :date
    field :complete, :boolean, default: false
    timestamps()
  end

  def changeset(rollup_log, attrs) do
    rollup_log
    |> cast(attrs, [:table_name, :date, :complete])
    |> validate_required([:table_name, :date, :complete])
  end

  def upsert(log) do
    conflict = [set: [updated_at: Timex.now(), complete: log.complete]]
    target = [:table_name, :date]
    Castle.Repo.insert!(log, on_conflict: conflict, conflict_target: target)
  end

  def find_missing(table_name, limit, to_date \\ nil) do
    query = """
      SELECT range.date FROM (#{select_range(to_date)}) as range
      WHERE range.date NOT IN
        (SELECT date FROM rollup_logs WHERE table_name = $1 AND complete = true)
      ORDER BY range.date DESC limit $2
      """ |> String.replace("\n", " ")
    {:ok, result} = Ecto.Adapters.SQL.query(Castle.Repo, query, [table_name, limit])
    Enum.map result.rows, &(range_to_struct(table_name, hd(&1)))
  end

  defp select_range(nil), do: select_range Timex.shift(Timex.now(), seconds: -@buffer_seconds)
  defp select_range("" <> to_date_str) do
    """
    SELECT r.DATE as date
    FROM GENERATE_SERIES('#{to_date_str}', '#{@beginning_of_time}', '-1 DAY'::INTERVAL) r
    """
  end
  defp select_range(to_date) do
    {:ok, date_str} = Timex.format(to_date, "{YYYY}-{0M}-{0D}")
    select_range(date_str)
  end

  defp range_to_struct(name, erl) do
    {:ok, date} = Date.from_erl(erl)
    %Castle.RollupLog{table_name: name, date: date}
  end
end
