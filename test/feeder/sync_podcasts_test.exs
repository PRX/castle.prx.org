defmodule Feeder.SyncPodcastsTest do
  use Castle.HttpCase
  use Castle.FeederHelpers
  use Castle.TimeHelpers

  test_with_http "updates nothing", %{@feeder_all_podcasts => %{}} do
    assert {:ok, 0, 0, 0} = Feeder.SyncPodcasts.sync()
  end

  test_with_http "creates and updates", %{@feeder_all_podcasts => mock_items(3)} do
    Castle.Repo.insert!(%Castle.Podcast{
      id: 123,
      title: "one",
      updated_at: get_dtim("2018-04-25T04:00:00Z")
    })

    Castle.Repo.insert!(%Castle.Podcast{
      id: 789,
      title: "three",
      updated_at: get_dtim("2018-04-25T04:00:00Z")
    })

    assert {:ok, 1, 2, 0} = Feeder.SyncPodcasts.sync("1970-01-01")
    assert Castle.Repo.get(Castle.Podcast, 123).title == "one-changed"
    assert Castle.Repo.get(Castle.Podcast, 456).title == "two"
    # updated_at stale
    assert Castle.Repo.get(Castle.Podcast, 789).title == "three"
  end

  test_with_http "has remaining items to process", %{@feeder_all_podcasts => mock_items(10)} do
    assert {:ok, 3, 0, 7} = Feeder.SyncPodcasts.sync()
  end

  defp mock_items(total) do
    %{
      "total" => total,
      "_embedded" => %{
        "prx:items" => [
          %{
            "id" => 123,
            "title" => "one-changed",
            "updatedAt" => "2018-04-25T05:00:00Z"
          },
          %{
            "id" => 456,
            "title" => "two",
            "updatedAt" => "2018-04-25T05:00:00Z"
          },
          %{
            "id" => 789,
            "title" => "three-changed",
            "updatedAt" => "2018-04-23T05:00:00Z"
          }
        ]
      }
    }
  end
end
