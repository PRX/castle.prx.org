defmodule Castle.Rollup.Data.TotalsTest do
  use Castle.RedisCase, async: true
  use Castle.TimeHelpers

  import Castle.Rollup.Data.Totals
  alias Castle.Redis.Conn, as: Conn

  @moduletag :redis
  @test_podcast "_test_podcast_id"
  @test_episode "_test_episode_guid"
  @last_updated "_last_updated"

  setup do
    today = format_dtim(Timex.now |> Timex.beginning_of_day)
    Conn.hset("rollups.totals.podcasts", @test_podcast, 444)
    Conn.hset("rollups.totals.podcasts", @last_updated, today)
    Conn.hset("downloads.podcasts.DAY.#{today}", @test_podcast, 33)
    Conn.hset("rollups.totals.episodes", @test_episode, 222)
    Conn.hset("rollups.totals.episodes", @last_updated, today)
    Conn.hset("downloads.episodes.DAY.#{today}", @test_episode, 11)
    []
  end

  test "gets nil for unknown podcats/episodes" do
    assert podcast("_does_not_exist") == nil
    assert episode("_does_not_exist") == nil
  end

  test "gets daily numbers added to the rollup" do
    assert podcast(@test_podcast) == 477
    assert episode(@test_episode) == 233
  end

end
