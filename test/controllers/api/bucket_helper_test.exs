defmodule Castle.API.BucketHelperTest do
  use Castle.ConnCase, async: true
  use Castle.TimeHelpers

  setup do
    [
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

  defp bucketize(original_data, buckets) do
    {data, _meta} = CastleWeb.API.BucketHelper.bucketize({original_data, %{}}, buckets)
    data
  end

  defp assert_times(data) do
    assert length(data) == 3
    times = Enum.map(data, &(&1.time))
    assert_time times, 0, "2017-03-26T00:00:00Z"
    assert_time times, 1, "2017-03-27T00:00:00Z"
    assert_time times, 2, "2017-03-28T00:00:00Z"
  end
end
