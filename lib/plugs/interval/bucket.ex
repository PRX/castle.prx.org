defmodule Castle.Plugs.Interval.Bucket do

  alias Castle.Bucket, as: Bucket

  @max_in_window 1000

  def parse(_conn, %{skip_bucket: true}), do: {:ok, nil}
  def parse(%{params: %{"interval" => interval}} = conn, %{min: min}) do
    buckets = get_buckets(min)
    match = Enum.find(buckets, &(&1.is_a?(interval)))
    if match do
      validate_window(conn, match)
    else
      options = buckets |> Enum.map(&(&1.name)) |> Enum.join(", ")
      {:error, "Bad interval param: use one of #{options}"}
    end
  end
  def parse(%{assigns: %{interval: %{from: from, to: to}}} = conn, %{min: min}) do
    buckets = get_buckets(min)
    best_guess = Enum.find buckets, List.last(buckets), &(&1.count_range(from, to) < 70)
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

  defp validate_window(%{assigns: %{interval: %{from: from, to: to}}}, rollup) do
    if rollup.count_range(from, to) > @max_in_window do
      {:error, "Time window too large for specified interval"}
    else
      {:ok, rollup}
    end
  end
end
