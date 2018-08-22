defmodule Castle.RedisTotalsCacheTest do
  use Castle.RedisCase, async: true
  use Castle.TimeHelpers

  @moduletag :redis

  alias Castle.Redis.TotalsCache, as: TotalsCache
  alias Castle.Redis.Conn, as: Conn

  @id "test-id"

  setup do
    redis_clear("totals.podcast.#{@id}.*")
    redis_clear("downloads.podcasts.HOUR.2018-05-01T12:00:00Z")
    redis_clear("downloads.podcasts.HOUR.2018-05-01T11:00:00Z")
    []
  end

  test "caches totals when no increments exist" do
    count = podcast_totals "2018-05-01T12:12:00Z", fn(dtim) ->
      assert_time dtim, "2018-05-01T12:12:00Z"
      9
    end
    assert count == 9

    # cache is keyed to "now", instead of a timestamp
    count2 = podcast_totals "2018-05-02T23:23:23Z", fn(_) -> %{} end
    assert count2 == 9
  end

  test "caches totals with increments" do
    Conn.hset "downloads.podcasts.HOUR.2018-05-01T12:00:00Z", @id, 1
    Conn.hset "downloads.podcasts.HOUR.2018-05-01T11:00:00Z", @id, 4
    count = podcast_totals "2018-05-01T12:12:00Z", fn(dtim) ->
      assert_time dtim, "2018-05-01T11:00:00Z"
      9
    end
    assert count == 14

    count2 = podcast_totals "2018-05-01T12:12:11Z", fn(_) -> %{} end
    assert count2 == 14
  end

  test "recomputes when you pass 15 after the hour" do
    Conn.hset "downloads.podcasts.HOUR.2018-05-01T12:00:00Z", @id, 1
    Conn.hset "downloads.podcasts.HOUR.2018-05-01T11:00:00Z", @id, 4
    count = podcast_totals "2018-05-01T12:12:00Z", fn(dtim) ->
      assert_time dtim, "2018-05-01T11:00:00Z"
      9
    end

    count2 = podcast_totals "2018-05-01T12:15:00Z", fn(dtim) ->
      assert_time dtim, "2018-05-01T12:00:00Z"
      9
    end
    assert count == 14
    assert count2 == 10
  end

  defp podcast_totals(now_str, work_fn) do
    TotalsCache.podcast_totals @id, get_dtim(now_str), work_fn
  end
end
