defmodule Castle.Rollup.Query.AgentRanks do
  import Ecto.Query
  alias Castle.Rollup.Query.AgentTotals, as: AgentTotals

  def podcast(id, %{from: from, to: to, bucket: bucket}, %{name: grouping_name, limit: num}) do
    podcast(id, from, to, bucket.rollup, grouping_name, num)
  end
  def podcast(id, from, to, trunc, grouping_name, grouping_limit) do
    top_n = AgentTotals.podcast(id, from, to, grouping_name, grouping_limit) |> Enum.map(&(&1.group))
    data = Castle.DailyAgent
      |> select_fields(trunc)
      |> select_grouping(grouping_name, top_n)
      |> where_podcast(id)
      |> where_timeframe(from, to)
      |> order_by([t], [asc: fragment("time"), asc: fragment("grouping")])
      |> Castle.Repo.all
    {top_n ++ [nil], data}
  end

  def episode(id, %{from: from, to: to, bucket: bucket}, %{name: grouping_name, limit: num}) do
    episode(id, from, to, bucket.rollup, grouping_name, num)
  end
  def episode(id, from, to, trunc, grouping_name, grouping_limit) do
    top_n = AgentTotals.episode(id, from, to, grouping_name, grouping_limit) |> Enum.map(&(&1.group))
    data = Castle.DailyAgent
      |> select_fields(trunc)
      |> select_grouping(grouping_name, top_n)
      |> where_episode(id)
      |> where_timeframe(from, to)
      |> order_by([t], [asc: fragment("time"), asc: fragment("grouping")])
      |> Castle.Repo.all
    {top_n ++ [nil], data}
  end

  defp select_fields(query, "week") do
    select(query, [t], %{count: sum(t.count)})
    |> select_merge([t], %{time: fragment("date_trunc('week',day+interval '1 day')::date-interval '1 day' as time")})
    |> group_by([t], [fragment("time")])
  end
  defp select_fields(query, trunc) do
    select(query, [t], %{count: sum(t.count)})
    |> select_merge([t], %{time: fragment("date_trunc(?,day)::date as time", ^trunc)})
    |> group_by([t], [fragment("time")])
  end

  defp select_grouping(query, "agentname", top_n) do
    select_grouping(query, :agent_name_id, top_n)
  end
  defp select_grouping(query, "agenttype", top_n) do
    select_grouping(query, :agent_type_id, top_n)
  end
  defp select_grouping(query, "agentos", top_n) do
    select_grouping(query, :agent_os_id, top_n)
  end
  defp select_grouping(query, fld, top_n) when is_atom(fld) do
    select_merge(query, [t], %{
      group: fragment("CASE WHEN ? = ANY(?) THEN ? ELSE null END as grouping",
                      field(t, ^fld), ^top_n, field(t, ^fld))
    }) |> group_by([t], [fragment("grouping")])
  end

  defp where_podcast(query, id) do
    where(query, [t], t.podcast_id == ^id) |> group_by([t], t.podcast_id)
  end

  defp where_episode(query, id) do
    where(query, [t], t.episode_id == ^id) |> group_by([t], t.episode_id)
  end

  defp where_timeframe(query, from, to) do
    where(query, [t], t.day >= ^from and t.day < ^to)
  end
end
