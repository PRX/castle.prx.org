defmodule Castle.Plugs.Interval.Bucket do
  alias Castle.Bucket, as: Bucket

  @max_in_window 1000

  def parse(_conn, %{skip_bucket: true}), do: {:ok, nil}

  def parse(%{params: %{"interval" => interval_type_label}} = conn, %{min: min}) do
    buckets = get_buckets(min)
    matched_bucket = Enum.find(buckets, & &1.is_a?(interval_type_label))

    if matched_bucket do
      validate_window(conn, matched_bucket)
    else
      {:error, "Bad interval param: use one of #{valid_bucket_labels(buckets, min)}"}
    end
  end

  def valid_bucket_labels(buckets, min) do
    bucket_label_grouping =
      case min do
        "LISTENER_UNIQUES_NON_AGGREGATED" -> :listeners_labels
        _ -> :downloads_labels
      end

    buckets
    |> Enum.flat_map(fn bucket -> apply(bucket, bucket_label_grouping, []) end)
    |> Enum.join(", ")
  end

  def parse(%{assigns: %{interval: %{from: from, to: to}}} = conn, %{min: min}) do
    buckets = get_buckets(min)
    best_guess = Enum.find(buckets, List.last(buckets), &(&1.count_range(from, to) < 70))
    validate_window(conn, best_guess)
  end

  def parse(_conn, _opts) do
    {:error, "Invalid interval params"}
  end

  defp get_buckets("HOUR") do
    [Bucket.Hourly, Bucket.Daily, Bucket.Weekly, Bucket.Monthly]
  end

  defp get_buckets("DAY") do
    [Bucket.Daily, Bucket.Weekly, Bucket.Monthly]
  end

  defp get_buckets("LISTENER_UNIQUES_NON_AGGREGATED") do
    [Bucket.Weekly, Bucket.Monthly]
  end

  def validate_window(%{assigns: %{interval: %{from: from, to: to}}}, bucket) do
    if bucket.count_range(from, to) > @max_in_window do
      {:error, "Time window too large for specified interval"}
    else
      {:ok, bucket}
    end
  end
end
