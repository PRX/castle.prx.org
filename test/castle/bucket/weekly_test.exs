defmodule Castle.CastleBucketWeeklyTest do
  use Castle.BigQueryCase, async: true

  import Castle.Bucket.Weekly

  defp format_floor(str), do: mutate_dtim(str, &floor/1)
  defp format_ceiling(str), do: mutate_dtim(str, &ceiling/1)
  defp format_next(str), do: mutate_dtim(str, &next/1)
  defp format_range(s1, s2), do: mutate_dtims(s1, s2, &range/2)
  defp get_count(s1, s2), do: call_dtims(s1, s2, &count_range/2)

  test "has basic data" do
    assert name() == "WEEK"
    assert rollup() == "week"
    assert is_a?("1w") == true
    assert is_a?("WEEK") == true
    assert is_a?("1m") == false
    assert is_a?("foo") == false
  end

  test "floors" do
    assert format_floor("2017-03-22T01:15:00Z") == "2017-03-19T00:00:00Z"
    assert format_floor("2017-03-19T00:00:00Z") == "2017-03-19T00:00:00Z"
    assert format_floor("2017-03-18T23:59:59Z") == "2017-03-12T00:00:00Z"
  end

  test "ceilings" do
    assert format_ceiling("2017-03-22T01:15:00Z") == "2017-03-26T00:00:00Z"
    assert format_ceiling("2017-03-19T00:00:00Z") == "2017-03-19T00:00:00Z"
    assert format_ceiling("2017-03-18T23:59:59Z") == "2017-03-19T00:00:00Z"
  end

  test "next" do
    assert format_next("2017-03-22T01:15:00Z") == "2017-03-26T00:00:00Z"
    assert format_next("2017-03-19T00:00:00Z") == "2017-03-26T00:00:00Z"
    assert format_next("2017-03-18T23:59:59Z") == "2017-03-19T00:00:00Z"
  end

  test "range" do
    range = format_range("2017-03-13T01:15:00Z", "2017-04-02T12:00:00Z")
    assert length(range) == 4
    assert Enum.at(range, 0) == "2017-03-12T00:00:00Z"
    assert Enum.at(range, 1) == "2017-03-19T00:00:00Z"
    assert Enum.at(range, 2) == "2017-03-26T00:00:00Z"
    assert Enum.at(range, 3) == "2017-04-02T00:00:00Z"

    range = format_range("2017-03-18T23:59:59Z", "2017-04-02T00:00:00Z")
    assert length(range) == 3
    assert Enum.at(range, 0) == "2017-03-12T00:00:00Z"
    assert Enum.at(range, 1) == "2017-03-19T00:00:00Z"
    assert Enum.at(range, 2) == "2017-03-26T00:00:00Z"
  end

  test "count range" do
    assert get_count("2017-03-13T01:15:00Z", "2017-03-28T12:00:00Z") == 3
    assert get_count("2017-03-13T01:15:00Z", "2017-03-26T00:00:00Z") == 2
    assert get_count("2017-03-13T01:15:00Z", "2017-04-21T12:00:00Z") == 6
  end
end
