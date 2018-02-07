defmodule Castle.Rollup.Data.TrendsTest do
  use Castle.ConnCase, async: false

  import Castle.Rollup.Data.Trends

  import Mock

  # TODO: this doesn't work unless you've "mix castle.rollup"d first
  # @tag :external
  # test "actually works" do
  #   pod_trends = podcast(25)
  #   assert pod_trends.last7 > 1000
  #   assert pod_trends.this7 > 1000
  #   assert pod_trends.yesterday > 100
  #   assert pod_trends.today > 1
  #
  #   ep_trends = episode("5209720b-e71e-454a-abaf-8ffaf542ac67")
  #   assert ep_trends.last7 > 100
  #   assert ep_trends.this7 > 100
  #   assert ep_trends.yesterday > 10
  #   assert ep_trends.today > 1
  # end

  test "gets podcast trends" do
    with_mock Castle.Rollup.Jobs.Trends, fake_getter() do
      assert podcast(5) == %{last7: 6, this7: 0, today: 3, yesterday: 1}
      assert podcast(6) == %{last7: 0, this7: 0, today: 11, yesterday: 0}
      assert podcast(7) == %{last7: 0, this7: 0, today: 0, yesterday: 0}
    end
  end

  test "gets episode trends" do
    with_mock Castle.Rollup.Jobs.Trends, fake_getter() do
      assert episode("guid1") == %{last7: 2, this7: 0, today: 0, yesterday: 1}
      assert episode("guid2") == %{last7: 4, this7: 0, today: 3, yesterday: 0}
      assert episode("guid3") == %{last7: 0, this7: 0, today: 11, yesterday: 0}
      assert episode("guid4") == %{last7: 0, this7: 0, today: 0, yesterday: 0}
    end
  end

  defp fake_getter do
    results = [
      %{feeder_episode: "guid2", feeder_podcast: 5, last7: 4},
      %{feeder_episode: "guid2", feeder_podcast: 5, today: 3},
      %{feeder_episode: "guid1", feeder_podcast: 5, last7: 2, yesterday: 1},
      %{feeder_episode: "guid3", feeder_podcast: 6, today: 11},
    ]
    [get: fn() -> {results, %{cached: true}} end]
  end

end
