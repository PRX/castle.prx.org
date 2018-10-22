defmodule Castle.Rollup.Query.GeoTotals do
  import Ecto.Query

  def podcast(id, %{from: from, to: to}, %{name: name, filters: filters}) do
    podcast(id, from, to, name, nil, filters)
  end
  def podcast(id, from, to, grouping_name, limit \\ nil, filters \\ nil) do
    table(grouping_name)
    |> select([t], %{count: sum(t.count)})
    |> select_grouping(grouping_name)
    |> where_podcast(id)
    |> where_timeframe(from, to)
    |> where_filters(grouping_name, filters)
    |> order_by([t], [desc: sum(t.count)])
    |> with_limit(limit)
    |> Castle.Repo.all
  end

  def episode(id, %{from: from, to: to}, %{name: name, filters: filters}) do
    episode(id, from, to, name, nil, filters)
  end
  def episode(id, from, to, grouping_name, limit \\ nil, filters \\ nil) do
    table(grouping_name)
    |> select([t], %{count: sum(t.count)})
    |> select_grouping(grouping_name)
    |> where_episode(id)
    |> where_timeframe(from, to)
    |> where_filters(grouping_name, filters)
    |> order_by([t], [desc: sum(t.count)])
    |> with_limit(limit)
    |> Castle.Repo.all
  end

  defp table("geocountry"), do: Castle.DailyGeoCountry
  defp table("geosubdiv"), do: Castle.DailyGeoSubdiv
  defp table("geometro"), do: Castle.DailyGeoMetro

  defp select_grouping(query, "geocountry") do
    select_merge(query, [t], %{group: t.country_iso_code})
    |> group_by([t], [t.country_iso_code])
  end
  defp select_grouping(query, "geosubdiv") do
    select_merge(query, [t], %{group: fragment("country_iso_code || '-' || subdivision_1_iso_code")})
    |> group_by([t], [t.country_iso_code, t.subdivision_1_iso_code])
  end
  defp select_grouping(query, "geometro") do
    select_merge(query, [t], %{group: t.metro_code})
    |> group_by([t], [t.metro_code])
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

  defp where_filters(query, "geosubdiv", %{geocountry: codes}) do
    codes_list = String.split(codes, "|", trim: true)
    where(query, [t], t.country_iso_code in ^codes_list)
  end
  defp where_filters(query, _, _), do: query

  defp with_limit(query, nil), do: query
  defp with_limit(query, num), do: limit(query, ^num)
end
