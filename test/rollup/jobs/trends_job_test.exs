defmodule Castle.Rollup.Jobs.TrendsTest do
  use Castle.BigQueryCase, async: true

  import Castle.Rollup.Jobs.Trends

  test "does nothing to combine results" do
    datas = [
      %{feeder_podcast: 123, feeder_episode: "123-1", last7: 22, this7: 11, yesterday: 4, today: 0},
      %{feeder_podcast: 123, feeder_episode: "123-2", last7: 0, this7: 0, yesterday: 0, today: 2},
      %{feeder_podcast: 456, feeder_episode: "456-1", this7: 12},
      %{feeder_podcast: 123, feeder_episode: "123-2", last7: 4, this7: 0, yesterday: 1, today: 0},
      %{feeder_podcast: 123, feeder_episode: "123-1", last7: 0, yesterday: 1, today: 2},
    ]
    results = combine(datas)
    assert results == datas
  end
end
