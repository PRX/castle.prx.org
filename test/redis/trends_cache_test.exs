defmodule Castle.RedisTrendsCacheTest do
  use Castle.RedisCase, async: true
  use Castle.TimeHelpers

  @moduletag :redis

  alias Castle.Redis.TrendsCache, as: TrendsCache
  alias Castle.Redis.Conn, as: Conn

  @id "test-id"

  setup do
    redis_clear("trends.podcast.#{@id}.*")
    redis_clear("downloads.podcasts.HOUR.2018-05-01T12:00:00Z")
    redis_clear("downloads.podcasts.HOUR.2018-05-01T11:00:00Z")
    [trends: %{total: 9, this7days: 8, previous7days: 7, yesterday: 3, today: 2}]
  end

  test "caches trends when no increments exist", %{trends: trends} do
    data = podcast_trends "2018-05-01T12:12:00Z", fn(dtim) ->
      assert_time dtim, "2018-05-01T12:12:00Z"
      trends
    end
    assert data == trends

    # cache is keyed to "now", instead of a timestamp
    data2 = podcast_trends "2018-05-02T23:23:23Z", fn(_) -> %{} end
    assert data2 == trends
  end

  test "caches trends with increments", %{trends: trends} do
    Conn.hset "downloads.podcasts.HOUR.2018-05-01T12:00:00Z", @id, 1
    Conn.hset "downloads.podcasts.HOUR.2018-05-01T11:00:00Z", @id, 4
    data = podcast_trends "2018-05-01T12:12:00Z", fn(dtim) ->
      assert_time dtim, "2018-05-01T11:00:00Z"
      trends
    end
    assert data != trends
    assert data.total == 14
    assert data.this7days == 13
    assert data.previous7days == 7
    assert data.yesterday == 3
    assert data.today == 7

    data2 = podcast_trends "2018-05-01T12:12:11Z", fn(_) -> %{} end
    assert data2 == data
  end

  test "recomputes when you pass 15 after the hour", %{trends: trends} do
    Conn.hset "downloads.podcasts.HOUR.2018-05-01T12:00:00Z", @id, 1
    Conn.hset "downloads.podcasts.HOUR.2018-05-01T11:00:00Z", @id, 4
    data = podcast_trends "2018-05-01T12:12:00Z", fn(dtim) ->
      assert_time dtim, "2018-05-01T11:00:00Z"
      trends
    end

    data2 = podcast_trends "2018-05-01T12:15:00Z", fn(dtim) ->
      assert_time dtim, "2018-05-01T12:00:00Z"
      trends |> Map.put(:today, 99)
    end
    assert data2 != data
    assert data2.this7days == data.this7days - 4 # does not include the 4
    assert data2.today == 100
    assert data2.total == data.total - 4
  end

  defp podcast_trends(now_str, work_fn) do
    TrendsCache.podcast_trends @id, get_dtim(now_str), work_fn
  end
end
