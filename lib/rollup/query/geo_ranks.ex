defmodule Castle.Rollup.Query.GeoRanks do
  import Ecto.Query
  alias Castle.Rollup.Query.GeoTotals, as: GeoTotals

  def podcast(id, %{from: from, to: to, bucket: bucket}, %{name: name, limit: limit, filters: filters}) do
    podcast(id, from, to, bucket.rollup, name, limit, filters)
  end
  def podcast(id, from, to, trunc, grouping_name, limit, filters \\ nil) do
    top_n = GeoTotals.podcast(id, from, to, grouping_name, limit, filters) |> Enum.map(&(&1.group))
    data = table(grouping_name)
      |> select_fields(trunc)
      |> select_grouping(grouping_name, top_n)
      |> where_podcast(id)
      |> where_timeframe(from, to)
      |> where_filters(grouping_name, filters)
      |> order_by([t], [asc: fragment("time"), asc: fragment("grouping")])
      |> Castle.Repo.NewRelic.all
    {top_n ++ [nil], data}
  end

  def episode(id, %{from: from, to: to, bucket: bucket}, %{name: name, limit: limit, filters: filters}) do
    episode(id, from, to, bucket.rollup, name, limit, filters)
  end
  def episode(id, from, to, trunc, grouping_name, limit, filters \\ nil) do
    top_n = GeoTotals.episode(id, from, to, grouping_name, limit, filters) |> Enum.map(&(&1.group))
    data = table(grouping_name)
      |> select_fields(trunc)
      |> select_grouping(grouping_name, top_n)
      |> where_episode(id)
      |> where_timeframe(from, to)
      |> where_filters(grouping_name, filters)
      |> order_by([t], [asc: fragment("time"), asc: fragment("grouping")])
      |> Castle.Repo.NewRelic.all
    {top_n ++ [nil], data}
  end

  defp table("geocountry"), do: Castle.DailyGeoCountry
  defp table("geosubdiv"), do: Castle.DailyGeoSubdiv
  defp table("geometro"), do: Castle.DailyGeoMetro

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

  defp select_grouping(query, "geocountry", top_n) do
    select_merge(query, [t], %{
      group: fragment("""
        CASE WHEN country_iso_code = ANY(?) THEN country_iso_code ELSE null END as grouping
      """, ^top_n)
    })
    |> group_by([t], [fragment("grouping")])
  end
  defp select_grouping(query, "geosubdiv", top_n) do
    select_merge(query, [t], %{
      group: fragment("""
        CASE WHEN country_iso_code || '-' || subdivision_1_iso_code = ANY(?)
        THEN country_iso_code || '-' || subdivision_1_iso_code
        ELSE null
        END as grouping
      """, ^top_n)
    })
    |> group_by([t], [fragment("grouping")])
  end
  defp select_grouping(query, "geometro", top_n) do
    select_merge(query, [t], %{
      group: fragment("""
        CASE WHEN metro_code = ANY(?) THEN metro_code ELSE null END as grouping
      """, ^top_n)
    })
    |> group_by([t], [fragment("grouping")])
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
end
