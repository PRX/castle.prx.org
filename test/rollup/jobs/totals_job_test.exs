defmodule Castle.Rollup.Jobs.TotalsTest do
  use Castle.BigQueryCase, async: false

  import Mock
  import Castle.Rollup.Jobs.Totals

  test "queries for podcasts" do
    now = Timex.now
    then = Timex.shift(now, days: -2)
    with_mock BigQuery.Base.Query, [query: fn(params, sql) ->
      assert params.lower == then
      assert params.upper == now
      assert sql =~ ~r/_PARTITIONTIME >= @lower/
      assert sql =~ ~r/_PARTITIONTIME < @upper/
      {[%{count: 10, key: 99}], %{cached: true}}
    end] do
      {data, meta} = query_podcasts(then, now)
      assert data == %{99 => 10}
      assert meta.cached == true
    end
  end

  test "queries for episodes" do
    now = Timex.now
    with_mock BigQuery.Base.Query, [query: fn(params, sql) ->
      assert Map.has_key?(params, :lower) == false
      assert params.upper == now
      refute sql =~ ~r/_PARTITIONTIME >= @lower/
      assert sql =~ ~r/_PARTITIONTIME < @upper/
      {[%{count: 10, key: "abcd"}], %{cached: true}}
    end] do
      {data, meta} = query_episodes(nil, now)
      assert data == %{"abcd" => 10}
      assert meta.cached == true
    end
  end
end
