import Mock

defmodule Castle.Rollup.Data.TotalsTest do
  use Castle.ConnCase, async: false

  import Castle.Rollup.Data.Totals

  # TODO: this doesn't work unless you've "mix castle.rollup"d first
  # @tag :external
  # test "actually works" do
  #   assert podcast_downloads(25) > 10000
  #   assert episode_downloads("d7a8935e-b735-4ecc-afff-0a804ac40fd9") > 100
  # end

  test "gets podcast download counts" do
    with_mock Castle.Rollup.Jobs.Totals, fake_getter() do
      assert podcast_downloads(5) == 14
      assert podcast_downloads(6) == 3
      assert podcast_downloads(7) == 0
    end
  end

  test "gets episode download counts" do
    with_mock Castle.Rollup.Jobs.Totals, fake_getter() do
      assert episode_downloads("guid1") == 9
      assert episode_downloads("guid2") == 5
      assert episode_downloads("guid3") == 3
      assert episode_downloads("guid4") == 0
    end
  end

  defp fake_getter do
    results = [
      %{count: 9, feeder_episode: "guid1", feeder_podcast: 5},
      %{count: 5, feeder_episode: "guid2", feeder_podcast: 5},
      %{count: 3, feeder_episode: "guid3", feeder_podcast: 6},
    ]
    [get: fn() -> {results, %{cached: true}} end]
  end

end
