defmodule Castle.RollupQueryGeoRanksTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Rollup.Query.GeoRanks

  @id 70
  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

  describe "geocountry" do

    setup do
      Castle.DailyGeoCountry.upsert %{podcast_id: @id, episode_id: @guid2, count: 11,
        day: ~D[2018-04-24], country_iso_code: "US"}
      Castle.DailyGeoCountry.upsert %{podcast_id: @id, episode_id: @guid1, count: 22,
        day: ~D[2018-04-24], country_iso_code: "FR"}
      Castle.DailyGeoCountry.upsert %{podcast_id: @id, episode_id: @guid1, count: 33,
        day: ~D[2018-04-24], country_iso_code: "CA"}
      Castle.DailyGeoCountry.upsert %{podcast_id: @id, episode_id: @guid1, count: 44,
        day: ~D[2018-04-24], country_iso_code: "AE"}
      Castle.DailyGeoCountry.upsert %{podcast_id: @id, episode_id: @guid2, count: 55,
        day: ~D[2018-04-25], country_iso_code: "US"}
      [t1: get_dtim("2018-04-24T00:00:00"), t2: get_dtim("2018-04-26T00:00:00")]
    end

    test "works", %{t1: t1, t2: t2} do
      {ranks, datas} = podcast(@id, t1, t2, "day", "geocountry", 2)
      assert ranks == ["US", "AE"]
      assert length(datas) == 4

      assert Enum.at(datas, 0).group == "AE"
      assert Enum.at(datas, 0).count == 44
      assert_time Enum.at(datas, 0).time, "2018-04-24T00:00:00Z"

      assert Enum.at(datas, 1).group == "US"
      assert Enum.at(datas, 1).count == 11
      assert_time Enum.at(datas, 1).time, "2018-04-24T00:00:00Z"

      assert Enum.at(datas, 2).group == nil
      assert Enum.at(datas, 2).count == 55
      assert_time Enum.at(datas, 2).time, "2018-04-24T00:00:00Z"

      assert Enum.at(datas, 3).group == "US"
      assert Enum.at(datas, 3).count == 55
      assert_time Enum.at(datas, 3).time, "2018-04-25T00:00:00Z"
    end

  end

end
