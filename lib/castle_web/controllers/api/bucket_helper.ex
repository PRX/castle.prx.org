defmodule CastleWeb.API.BucketHelper do

  # put the data counts into their respective timestamp buckets
  # (assumes both data and buckets are sorted timestamp-ASC)
  def bucketize(data, %{from: from, to: to, bucket: bucket}) do
    range = adjust_range(from, bucket.range(from, to))
    bucketize(data, range)
  end
  def bucketize(data, buckets) when is_list(buckets) do
    combine_data(buckets, data)
  end

  # bucketize, but with groupings
  def bucketize_groups(ranks, data, intv) do
    filter_and_bucket_groups(ranks, data, intv) |> List.zip |> refactor_groups(ranks)
  end

  # make sure first bucket reflects the ACTUAL start time
  defp adjust_range(start_at, [_first | rest]), do: [start_at] ++ rest
  defp adjust_range(_start_at, []), do: []

  # POP next bucket off the stack, or just return when out of buckets
  defp combine_data([], _datas), do: []
  defp combine_data([next_bucket | rest_buckets], data) do
    combine_data(next_bucket, 0, rest_buckets, data)
  end

  # check if current time/count is in this bucket or not
  defp combine_data(
    bucket,
    count,
    [next_bucket | _rest_buckets] = buckets,
    [%{time: t, count: c} | rest_data] = datas
  ) do
    if Timex.compare(next_bucket, t) > 0 do
      combine_data(bucket, count + c, buckets, rest_data)
    else
      [%{time: bucket, count: count}] ++ combine_data(buckets, datas)
    end
  end

  # out of data - just return 0s for remaining buckets
  defp combine_data(bucket, count, buckets, []) do
    [%{time: bucket, count: count}] ++ combine_data(buckets, [])
  end

  # out of buckets - add remaining times to last bucket
  defp combine_data(bucket, count, [], [%{count: c} | rest_data]) do
    combine_data(bucket, count + c, [], rest_data)
  end

  defp filter_and_bucket_groups(groups, data, intv) do
    Enum.map groups, fn(group) ->
      data |> Enum.filter(&(&1.group == group)) |> bucketize(intv)
    end
  end

  defp refactor_groups([], _groups), do: []
  defp refactor_groups([data | rest], groups) do
    list_data = Tuple.to_list(data)
    counts = Enum.map(list_data, &(&1.count))
    [%{time: hd(list_data).time, counts: counts, ranks: groups}] ++ refactor_groups(rest, groups)
  end
end
