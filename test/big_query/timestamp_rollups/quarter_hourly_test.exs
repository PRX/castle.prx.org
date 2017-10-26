defmodule Castle.BigQueryTimestampRollupsQuarterHourlyTest do
  use Castle.BigQueryCase, async: true

  import BigQuery.TimestampRollups.QuarterHourly

  defp format_floor(str), do: mutate_dtim(str, &floor/1)
  defp format_ceiling(str), do: mutate_dtim(str, &ceiling/1)
  defp format_range(s1, s2, ex), do: mutate_dtims(s1, s2, ex, &range/3)
  defp get_count(s1, s2), do: call_dtims(s1, s2, &count_range/2)

  test "has basic data" do
    assert name() == "15MIN"
    assert rollup() =~ ~r/MOD\(UNIX_SECONDS\(timestamp\), 900\)/
    assert is_a?("15m") == true
    assert is_a?("15MIN") == true
    assert is_a?("1w") == false
    assert is_a?("foo") == false
  end

  test "floors" do
    assert format_floor("2017-03-22T01:14:00Z") == "2017-03-22T01:00:00Z"
    assert format_floor("2017-03-22T01:15:00Z") == "2017-03-22T01:15:00Z"
    assert format_floor("2017-03-31T23:59:59Z") == "2017-03-31T23:45:00Z"
  end

  test "ceilings" do
    assert format_ceiling("2017-03-22T01:14:00Z") == "2017-03-22T01:15:00Z"
    assert format_ceiling("2017-03-22T01:15:00Z") == "2017-03-22T01:15:00Z"
    assert format_ceiling("2017-03-31T23:59:59Z") == "2017-04-01T00:00:00Z"
  end

  test "exclusive range" do
    range = format_range("2017-03-22T01:14:00Z", "2017-03-22T02:00:00Z", false)
    assert length(range) == 4
    assert Enum.at(range, 0) == "2017-03-22T01:00:00Z"
    assert Enum.at(range, 1) == "2017-03-22T01:15:00Z"
    assert Enum.at(range, 2) == "2017-03-22T01:30:00Z"
    assert Enum.at(range, 3) == "2017-03-22T01:45:00Z"

    range = format_range("2017-03-22T01:15:00Z", "2017-03-22T02:00:01Z", false)
    assert length(range) == 4
    assert Enum.at(range, 0) == "2017-03-22T01:15:00Z"
    assert Enum.at(range, 1) == "2017-03-22T01:30:00Z"
    assert Enum.at(range, 2) == "2017-03-22T01:45:00Z"
    assert Enum.at(range, 3) == "2017-03-22T02:00:00Z"
  end

  test "inclusive range" do
    range = format_range("2017-03-22T01:14:00Z", "2017-03-22T02:00:00Z", true)
    assert length(range) == 5
    assert Enum.at(range, 0) == "2017-03-22T01:00:00Z"
    assert Enum.at(range, 1) == "2017-03-22T01:15:00Z"
    assert Enum.at(range, 2) == "2017-03-22T01:30:00Z"
    assert Enum.at(range, 3) == "2017-03-22T01:45:00Z"
    assert Enum.at(range, 4) == "2017-03-22T02:00:00Z"
  end

  test "count range" do
    assert get_count("2017-03-22T01:15:00Z", "2017-03-22T02:00:01Z") == 4
    assert get_count("2017-03-22T01:14:00Z", "2017-03-22T02:00:01Z") == 5
    assert get_count("2017-03-22T01:14:59Z", "2017-03-22T02:00:00Z") == 4
  end
end