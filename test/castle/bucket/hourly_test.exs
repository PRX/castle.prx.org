defmodule Castle.CastleBucketHourlyTest do
  use Castle.BigQueryCase, async: true

  import Castle.Bucket.Hourly

  defp format_floor(str), do: mutate_dtim(str, &Castle.Bucket.Hourly.floor/1)
  defp format_ceiling(str), do: mutate_dtim(str, &ceiling/1)
  defp format_next(str), do: mutate_dtim(str, &next/1)
  defp format_range(s1, s2), do: mutate_dtims(s1, s2, &range/2)
  defp get_count(s1, s2), do: call_dtims(s1, s2, &count_range/2)

  test "has basic data" do
    assert name() == "HOUR"
    assert rollup() == "hour"
    assert is_a?("1h") == true
    assert is_a?("HOUR") == true
    assert is_a?("1w") == false
    assert is_a?("foo") == false
  end

  test "floors" do
    assert format_floor("2017-03-22T01:15:00Z") == "2017-03-22T01:00:00Z"
    assert format_floor("2017-03-01T00:00:00Z") == "2017-03-01T00:00:00Z"
    assert format_floor("2017-03-31T23:59:59Z") == "2017-03-31T23:00:00Z"
  end

  test "ceilings" do
    assert format_ceiling("2017-03-22T01:15:00Z") == "2017-03-22T02:00:00Z"
    assert format_ceiling("2017-03-01T00:00:00Z") == "2017-03-01T00:00:00Z"
    assert format_ceiling("2017-03-31T23:59:59Z") == "2017-04-01T00:00:00Z"
  end

  test "next" do
    assert format_next("2017-03-22T01:15:00Z") == "2017-03-22T02:00:00Z"
    assert format_next("2017-03-01T00:00:00Z") == "2017-03-01T01:00:00Z"
    assert format_next("2017-03-31T23:59:59Z") == "2017-04-01T00:00:00Z"
  end

  test "range" do
    range = format_range("2017-03-22T23:15:00Z", "2017-03-23T03:00:00Z")
    assert length(range) == 4
    assert Enum.at(range, 0) == "2017-03-22T23:00:00Z"
    assert Enum.at(range, 1) == "2017-03-23T00:00:00Z"
    assert Enum.at(range, 2) == "2017-03-23T01:00:00Z"
    assert Enum.at(range, 3) == "2017-03-23T02:00:00Z"

    range = format_range("2017-03-22T23:00:00Z", "2017-03-23T01:59:59Z")
    assert length(range) == 3
    assert Enum.at(range, 0) == "2017-03-22T23:00:00Z"
    assert Enum.at(range, 1) == "2017-03-23T00:00:00Z"
    assert Enum.at(range, 2) == "2017-03-23T01:00:00Z"
  end

  test "count range" do
    assert get_count("2017-03-22T23:15:00Z", "2017-03-23T01:59:59Z") == 3
    assert get_count("2017-03-22T23:00:00Z", "2017-03-23T02:00:00Z") == 3
    assert get_count("2017-03-22T23:15:00Z", "2017-03-24T02:00:00Z") == 27
  end
end
