defmodule Castle.Rollup.Data.TrendsTest do
  use Castle.RedisCase, async: false
  use Castle.TimeHelpers

  import Castle.Rollup.Data.Trends
  alias Castle.Redis.Conn, as: Conn

  @moduletag :redis
  @test_podcast "_test_podcast_id"
  @test_episode "_test_episode_guid"

  setup do
    redis_clear("downloads.*")
    today = format_dtim(Timex.now |> Timex.beginning_of_day)
    yesterday = format_dtim(Timex.now |> Timex.beginning_of_day |> Timex.shift(days: -1))
    last_week = format_dtim(Timex.now |> Timex.beginning_of_day |> Timex.shift(days: -10))
    Conn.hset("downloads.podcasts.DAY.#{today}", @test_podcast, 11)
    Conn.hset("downloads.podcasts.DAY.#{yesterday}", @test_podcast, 22)
    Conn.hset("downloads.podcasts.DAY.#{last_week}", @test_podcast, 333)
    Conn.hset("downloads.episodes.DAY.#{today}", @test_episode, 44)
    Conn.hset("downloads.episodes.DAY.#{last_week}", @test_episode, 55)
    []
  end

  test "gets podcast trends" do
    assert podcast("_does_not_exist") == %{last7: 0, this7: 0, today: 0, yesterday: 0}
    assert podcast(@test_podcast) == %{last7: 333, this7: 33, today: 11, yesterday: 22}
  end

  test "gets episode trends" do
    assert episode("_does_not_exist") == %{last7: 0, this7: 0, today: 0, yesterday: 0}
    assert episode(@test_episode) == %{last7: 55, this7: 44, today: 44, yesterday: 0}
  end

end
