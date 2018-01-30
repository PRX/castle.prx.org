defmodule CastleWeb.API.BucketHelper do

  # put the data counts into their respective timestamp buckets
  # (assumes both data and buckets are sorted timestamp-ASC)
  def bucketize(result, %{from: from, to: to, bucket: bucket}) do
    range = adjust_range(from, bucket.range(from, to))
    bucketize(result, range)
  end
  def bucketize({data, meta}, buckets) when is_list(buckets) do
    {combine_data(buckets, data), meta}
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
end
