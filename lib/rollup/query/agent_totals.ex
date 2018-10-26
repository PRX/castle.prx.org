defmodule Castle.Rollup.Query.AgentTotals do
  import Ecto.Query

  def podcast(id, %{from: from, to: to}, %{name: grouping_name}) do
    podcast(id, from, to, grouping_name)
  end
  def podcast(id, from, to, grouping_name, grouping_limit \\ nil) do
    Castle.DailyAgent
    |> select([t], %{count: sum(t.count)})
    |> select_grouping(grouping_name)
    |> where_podcast(id)
    |> where_timeframe(from, to)
    |> order_by([t], [desc: sum(t.count)])
    |> with_limit(grouping_limit)
    |> Castle.Repo.all
  end

  def episode(id, %{from: from, to: to}, %{name: grouping_name}) do
    episode(id, from, to, grouping_name)
  end
  def episode(id, from, to, grouping_name, grouping_limit \\ nil) do
    Castle.DailyAgent
    |> select([t], %{count: sum(t.count)})
    |> select_grouping(grouping_name)
    |> where_episode(id)
    |> where_timeframe(from, to)
    |> order_by([t], [desc: sum(t.count)])
    |> with_limit(grouping_limit)
    |> Castle.Repo.all
  end

  defp select_grouping(query, "agentname") do
    select_merge(query, [t], %{group: t.agent_name_id}) |> group_by([t], [t.agent_name_id])
  end
  defp select_grouping(query, "agenttype") do
    select_merge(query, [t], %{group: t.agent_type_id}) |> group_by([t], [t.agent_type_id])
  end
  defp select_grouping(query, "agentos") do
    select_merge(query, [t], %{group: t.agent_os_id}) |> group_by([t], [t.agent_os_id])
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

  defp with_limit(query, nil), do: query
  defp with_limit(query, num), do: limit(query, ^num)
end
