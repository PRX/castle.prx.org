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

    test "ranks a podcast", %{t1: t1, t2: t2} do
      {ranks, datas} = podcast(@id, t1, t2, "day", "geocountry", 2)
      assert ranks == ["US", "AE", nil]
      assert length(datas) == 4
      assert_result datas, 0, "AE", 44, "2018-04-24"
      assert_result datas, 1, "US", 11, "2018-04-24"
      assert_result datas, 2, nil, 55, "2018-04-24"
      assert_result datas, 3, "US", 55, "2018-04-25"
    end

    test "ranks an episode", %{t1: t1, t2: t2} do
      {ranks, datas} = episode(@guid1, t1, t2, "day", "geocountry", 2)
      assert ranks == ["AE", "CA", nil]
      assert length(datas) == 3
      assert_result datas, 0, "AE", 44, "2018-04-24"
      assert_result datas, 1, "CA", 33, "2018-04-24"
      assert_result datas, 2, nil, 22, "2018-04-24"
    end

  end

  describe "geosubdiv" do

    setup do
      Castle.DailyGeoSubdiv.upsert %{podcast_id: @id, episode_id: @guid1, count: 11,
        day: ~D[2018-04-24], country_iso_code: "US", subdivision_1_iso_code: "CO"}
      Castle.DailyGeoSubdiv.upsert %{podcast_id: @id, episode_id: @guid1, count: 22,
        day: ~D[2018-04-24], country_iso_code: "US", subdivision_1_iso_code: "CA"}
      Castle.DailyGeoSubdiv.upsert %{podcast_id: @id, episode_id: @guid2, count: 33,
        day: ~D[2018-04-25], country_iso_code: "US", subdivision_1_iso_code: "CO"}
      Castle.DailyGeoSubdiv.upsert %{podcast_id: @id, episode_id: @guid1, count: 44,
        day: ~D[2018-04-25], country_iso_code: "US", subdivision_1_iso_code: "MN"}
      [t1: get_dtim("2018-04-24T00:00:00"), t2: get_dtim("2018-04-26T00:00:00")]
    end

    test "ranks a podcast", %{t1: t1, t2: t2} do
      {ranks, datas} = podcast(@id, t1, t2, "day", "geosubdiv", 2)
      assert ranks == ["US-CO", "US-MN", nil]
      assert length(datas) == 4
      assert_result datas, 0, "US-CO", 11, "2018-04-24"
      assert_result datas, 1, nil, 22, "2018-04-24"
      assert_result datas, 2, "US-CO", 33, "2018-04-25"
      assert_result datas, 3, "US-MN", 44, "2018-04-25"
    end

    test "ranks an episode", %{t1: t1, t2: t2} do
      {ranks, datas} = episode(@guid1, t1, t2, "day", "geosubdiv", 2)
      assert ranks == ["US-MN", "US-CA", nil]
      assert length(datas) == 3
      assert_result datas, 0, "US-CA", 22, "2018-04-24"
      assert_result datas, 1, nil, 11, "2018-04-24"
      assert_result datas, 2, "US-MN", 44, "2018-04-25"
    end

  end

  describe "geometro" do

    setup do
      Castle.DailyGeoMetro.upsert %{podcast_id: @id, episode_id: @guid1, count: 11,
        day: ~D[2018-04-24], metro_code: 9876}
      Castle.DailyGeoMetro.upsert %{podcast_id: @id, episode_id: @guid1, count: 22,
        day: ~D[2018-04-24], metro_code: 5432}
      Castle.DailyGeoMetro.upsert %{podcast_id: @id, episode_id: @guid2, count: 33,
        day: ~D[2018-04-25], metro_code: 9876}
      Castle.DailyGeoMetro.upsert %{podcast_id: @id, episode_id: @guid1, count: 44,
        day: ~D[2018-04-25], metro_code: 1234}
      [t1: get_dtim("2018-04-24T00:00:00"), t2: get_dtim("2018-04-26T00:00:00")]
    end

    test "ranks a podcast", %{t1: t1, t2: t2} do
      {ranks, datas} = podcast(@id, t1, t2, "day", "geometro", 2)
      assert ranks == [1234, 9876, nil]
      assert length(datas) == 4
      assert_result datas, 0, 9876, 11, "2018-04-24"
      assert_result datas, 1, nil, 22, "2018-04-24"
      assert_result datas, 2, 1234, 44, "2018-04-25"
      assert_result datas, 3, 9876, 33, "2018-04-25"
    end

    test "ranks an episode", %{t1: t1, t2: t2} do
      {ranks, datas} = episode(@guid1, t1, t2, "day", "geometro", 2)
      assert ranks == [1234, 5432, nil]
      assert length(datas) == 3
      assert_result datas, 0, 5432, 22, "2018-04-24"
      assert_result datas, 1, nil, 11, "2018-04-24"
      assert_result datas, 2, 1234, 44, "2018-04-25"
    end

  end

  defp assert_result(datas, index, group, count, date_str) do
    assert Enum.at(datas, index).group == group
    assert Enum.at(datas, index).count == count
    assert_time Enum.at(datas, index).time, "#{date_str}T00:00:00Z"
  end

end
