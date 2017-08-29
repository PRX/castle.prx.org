defmodule Castle.Rollup.Jobs.TotalsTest do
  use Castle.BigQueryCase, async: true

  import Castle.Rollup.Jobs.Totals

  test "combines results" do
    results = combine([
      %{count: 1, feeder_podcast: 123, feeder_episode: "123-1"},
      %{count: 3, feeder_podcast: 123, feeder_episode: "123-2"},
      %{count: 7, feeder_podcast: 456, feeder_episode: "456-1"},
      %{count: 9, feeder_podcast: 789, feeder_episode: "789-1"},
      %{count: 2, feeder_podcast: 123, feeder_episode: "123-2"},
      %{count: 4, feeder_podcast: 789, feeder_episode: "789-2"},
      %{count: 6, feeder_podcast: 123, feeder_episode: "123-1"},
    ])

    assert podcast(results, "123-1") == 123
    assert count(results, "123-1") == 7
    assert podcast(results, "123-2") == 123
    assert count(results, "123-2") == 5
    assert podcast(results, "456-1") == 456
    assert count(results, "456-1") == 7
    assert podcast(results, "789-1") == 789
    assert count(results, "789-1") == 9
    assert podcast(results, "789-2") == 789
    assert count(results, "789-2") == 4
  end

  defp podcast(results, guid) do
    Enum.find(results, &(&1.feeder_episode == guid)).feeder_podcast
  end

  defp count(results, guid) do
    Enum.find(results, &(&1.feeder_episode == guid)).count
  end
end
