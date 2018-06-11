defmodule Castle.API.BucketHelperTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  import CastleWeb.API.BucketHelper

  setup do
    [
      from: get_dtim("2017-03-26T00:00:00Z"),
      to: get_dtim("2017-03-29T00:00:00Z"),
      buckets: [
        get_dtim("2017-03-26T00:00:00Z"),
        get_dtim("2017-03-27T00:00:00Z"),
        get_dtim("2017-03-28T00:00:00Z"),
      ]
    ]
  end

  test "combines data", %{buckets: buckets} do
    raw = [
      %{time: get_dtim("2017-03-26T10:00:00Z"), count: 1},
      %{time: get_dtim("2017-03-27T11:00:00Z"), count: 2},
      %{time: get_dtim("2017-03-27T15:00:00Z"), count: 3},
      %{time: get_dtim("2017-03-28T00:00:00Z"), count: 4},
      %{time: get_dtim("2017-03-28T00:00:01Z"), count: 5},
    ]
    data = bucketize(raw, buckets)
    assert_times(data)
    assert Enum.at(data, 0).count == 1
    assert Enum.at(data, 1).count == 5
    assert Enum.at(data, 2).count == 9
  end

  test "works with a bigquery interval", %{from: from, to: to} do
    interval = %Castle.Interval{
      from: from,
      to: to,
      bucket: Castle.Bucket.Daily,
    }
    data = bucketize([], interval)
    assert_times(data)
  end

  test "adjust the start time for the first interval bucket", %{to: to} do
    interval = %Castle.Interval{
      from: get_dtim("2017-03-26T12:00:00Z"),
      to: to,
      bucket: Castle.Bucket.Daily,
    }
    data = bucketize([], interval)
    assert length(data) == 3
    times = Enum.map(data, &(&1.time))
    assert_time times, 0, "2017-03-26T12:00:00Z"
    assert_time times, 1, "2017-03-27T00:00:00Z"
    assert_time times, 2, "2017-03-28T00:00:00Z"
  end

  test "handles empty first or last buckets", %{buckets: buckets} do
    raw = [%{time: get_dtim("2017-03-27T11:00:00Z"), count: 2}]
    data = bucketize(raw, buckets)
    assert_times(data)
    assert Enum.at(data, 0).count == 0
    assert Enum.at(data, 1).count == 2
    assert Enum.at(data, 2).count == 0
  end

  test "handles all empty", %{buckets: buckets} do
    data = bucketize([], buckets)
    assert_times(data)
    assert Enum.at(data, 0).count == 0
    assert Enum.at(data, 1).count == 0
    assert Enum.at(data, 2).count == 0
  end

  test "handles data before first bucket", %{buckets: buckets} do
    raw = [
      %{time: get_dtim("2017-01-26T10:00:00Z"), count: 1},
      %{time: get_dtim("2017-03-26T11:00:00Z"), count: 0},
      %{time: get_dtim("2017-03-27T11:00:00Z"), count: 2},
    ]
    data = bucketize(raw, buckets)
    assert_times(data)
    assert Enum.at(data, 0).count == 1
    assert Enum.at(data, 1).count == 2
    assert Enum.at(data, 2).count == 0
  end

  test "handles data after last bucket", %{buckets: buckets} do
    raw = [
      %{time: get_dtim("2017-03-27T00:00:00Z"), count: 4},
      %{time: get_dtim("2018-01-01T00:00:01Z"), count: 5},
    ]
    data = bucketize(raw, buckets)
    assert_times(data)
    assert Enum.at(data, 0).count == 0
    assert Enum.at(data, 1).count == 4
    assert Enum.at(data, 2).count == 5
  end

  test "combines grouped data", %{from: from, to: to} do
    interval = %Castle.Interval{from: from, to: to, bucket: Castle.Bucket.Daily}
    raw = [
      %{time: get_dtim("2017-03-26T10:00:00Z"), count: 1, group: "one"},
      %{time: get_dtim("2017-03-27T11:00:00Z"), count: 2, group: "one"},
      %{time: get_dtim("2017-03-27T11:00:00Z"), count: 2, group: nil},
      %{time: get_dtim("2017-03-27T15:00:00Z"), count: 3, group: "two"},
      %{time: get_dtim("2017-03-28T00:00:00Z"), count: 4, group: "one"},
      %{time: get_dtim("2017-03-28T00:00:01Z"), count: 5, group: "two"},
    ]
    data = bucketize_groups(["two", "one", nil], raw, interval)
    assert_times(data)
    assert Enum.at(data, 0).ranks == ["two", "one", nil]
    assert Enum.at(data, 1).ranks == ["two", "one", nil]
    assert Enum.at(data, 2).ranks == ["two", "one", nil]
    assert Enum.at(data, 0).counts == [0, 1, 0]
    assert Enum.at(data, 1).counts == [3, 2, 2]
    assert Enum.at(data, 2).counts == [5, 4, 0]
  end

  defp assert_times(data) do
    assert length(data) == 3
    times = Enum.map(data, &(&1.time))
    assert_time times, 0, "2017-03-26T00:00:00Z"
    assert_time times, 1, "2017-03-27T00:00:00Z"
    assert_time times, 2, "2017-03-28T00:00:00Z"
  end
end
