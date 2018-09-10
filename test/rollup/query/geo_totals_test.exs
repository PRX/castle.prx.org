defmodule Castle.RollupQueryGeoTotalsTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Rollup.Query.GeoTotals

  @id 70
  @guid1 "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
  @guid2 "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"

  describe "geocountry" do

    setup do
      Castle.DailyGeoCountry.upsert %{podcast_id: @id, episode_id: @guid1, count: 11,
        day: ~D[2018-04-24], country_iso_code: "US"}
      Castle.DailyGeoCountry.upsert %{podcast_id: @id, episode_id: @guid1, count: 22,
        day: ~D[2018-04-24], country_iso_code: "FR"}
      Castle.DailyGeoCountry.upsert %{podcast_id: @id, episode_id: @guid2, count: 33,
        day: ~D[2018-04-25], country_iso_code: "CA"}
      [t1: get_dtim("2018-04-24T00:00:00"), t2: get_dtim("2018-04-26T00:00:00")]
    end

    test "totals a podcast", %{t1: t1, t2: t2} do
      totals = podcast(@id, t1, t2, "geocountry")
      assert length(totals) == 3
      assert Enum.at(totals, 0).group == "CA"
      assert Enum.at(totals, 0).count == 33
      assert Enum.at(totals, 1).group == "FR"
      assert Enum.at(totals, 1).count == 22
      assert Enum.at(totals, 2).group == "US"
      assert Enum.at(totals, 2).count == 11
    end

    test "totals an episode", %{t1: t1, t2: t2} do
      totals = episode(@guid1, t1, t2, "geocountry")
      assert length(totals) == 2
      assert Enum.at(totals, 0).group == "FR"
      assert Enum.at(totals, 0).count == 22
      assert Enum.at(totals, 1).group == "US"
      assert Enum.at(totals, 1).count == 11
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
      Castle.DailyGeoSubdiv.upsert %{podcast_id: @id, episode_id: @guid2, count: 1,
        day: ~D[2018-04-25], country_iso_code: "CA", subdivision_1_iso_code: "ON"}
      [t1: get_dtim("2018-04-24T00:00:00"), t2: get_dtim("2018-04-26T00:00:00")]
    end

    test "totals a podcast", %{t1: t1, t2: t2} do
      totals = podcast(@id, t1, t2, "geosubdiv")
      assert length(totals) == 3
      assert Enum.at(totals, 0).group == "US-CO"
      assert Enum.at(totals, 0).count == 44
      assert Enum.at(totals, 1).group == "US-CA"
      assert Enum.at(totals, 1).count == 22
      assert Enum.at(totals, 2).group == "CA-ON"
      assert Enum.at(totals, 2).count == 1
    end

    test "totals an episode", %{t1: t1, t2: t2} do
      totals = episode(@guid1, t1, t2, "geosubdiv")
      assert length(totals) == 2
      assert Enum.at(totals, 0).group == "US-CA"
      assert Enum.at(totals, 0).count == 22
      assert Enum.at(totals, 1).group == "US-CO"
      assert Enum.at(totals, 1).count == 11
    end

    test "filters by a country", %{t1: t1, t2: t2} do
      totals = podcast(@id, t1, t2, "geosubdiv", nil, %{geocountry: "GB|CA"})
      assert length(totals) == 1
      assert Enum.at(totals, 0).group == "CA-ON"
      assert Enum.at(totals, 0).count == 1
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
      [t1: get_dtim("2018-04-24T00:00:00"), t2: get_dtim("2018-04-26T00:00:00")]
    end

    test "totals a podcast", %{t1: t1, t2: t2} do
      totals = podcast(@id, t1, t2, "geometro")
      assert length(totals) == 2
      assert Enum.at(totals, 0).group == 9876
      assert Enum.at(totals, 0).count == 44
      assert Enum.at(totals, 1).group == 5432
      assert Enum.at(totals, 1).count == 22
    end

    test "totals an episode", %{t1: t1, t2: t2} do
      totals = episode(@guid1, t1, t2, "geometro")
      assert length(totals) == 2
      assert Enum.at(totals, 0).group == 5432
      assert Enum.at(totals, 0).count == 22
      assert Enum.at(totals, 1).group == 9876
      assert Enum.at(totals, 1).count == 11
    end

  end

end
