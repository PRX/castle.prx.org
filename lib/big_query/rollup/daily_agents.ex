defmodule BigQuery.Rollup.DailyAgents do
  alias BigQuery.Base.Query, as: Query

  def query(), do: query(Timex.now)
  def query(dtim) do
    BigQuery.Rollup.for_day dtim, fn(day) ->
      {:ok, date_str} = Timex.format(day, "{YYYY}-{0M}-{0D}")
      Query.query(%{date_str: date_str}, sql()) |> format_results(day)
    end
  end

  defp sql do
    """
    SELECT
      ANY_VALUE(feeder_podcast) as podcast_id,
      feeder_episode as episode_id,
      IFNULL(agent_name_id, 0) as agent_name_id,
      IFNULL(agent_type_id, 0) as agent_type_id,
      IFNULL(agent_os_id, 0) as agent_os_id,
      count(*) as count
    FROM dt_downloads
    WHERE EXTRACT(DATE from timestamp) = @date_str AND is_duplicate = false
      AND feeder_podcast IS NOT NULL AND feeder_episode IS NOT NULL
    GROUP BY feeder_episode, agent_name_id, agent_type_id, agent_os_id
    """
  end

  defp format_results({rows, meta}, from) do
    day = Timex.beginning_of_day(from) |> Timex.to_date()
    {Enum.map(rows, &(format_result(&1, day))), meta}
  end

  defp format_result(row, day) do
    Map.put(row, :day, day)
  end
end
