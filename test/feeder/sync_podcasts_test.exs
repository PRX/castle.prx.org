defmodule Feeder.SyncPodcastsTest do
  use Castle.HttpCase
  use Castle.TimeHelpers

  @podcasts "https://feeder.prx.org/api/v1/podcasts?per=100&since=1970-01-01"

  test_with_http "updates nothing", %{@podcasts => %{}} do
    assert {:ok, 0, 0, 0} = Feeder.SyncPodcasts.sync()
  end

  test_with_http "creates and updates", %{@podcasts => updates_and_creates(3)} do
    Castle.Repo.insert!(%Castle.Podcast{id: 123, title: "one", updated_at: get_dtim("2018-04-25T04:00:00Z")})
    Castle.Repo.insert!(%Castle.Podcast{id: 789, title: "three", updated_at: get_dtim("2018-04-25T04:00:00Z")})
    assert {:ok, 1, 2, 0} = Feeder.SyncPodcasts.sync()
    assert Castle.Repo.get(Castle.Podcast, 123).title == "one-changed"
    assert Castle.Repo.get(Castle.Podcast, 456).title == "two"
    assert Castle.Repo.get(Castle.Podcast, 789).title == "three" # updated_at stale
  end

  test_with_http "has remaining items to process", %{@podcasts => updates_and_creates(10)} do
    assert {:ok, 3, 0, 7} = Feeder.SyncPodcasts.sync()
  end

  defp updates_and_creates(total) do
    %{
      "total" => total,
      "_embedded" => %{
        "prx:items" => [
          %{
            "id" => 123,
            "title" => "one-changed",
            "updatedAt" => "2018-04-25T05:00:00Z",
          },
          %{
            "id" => 456,
            "title" => "two",
            "updatedAt" => "2018-04-25T05:00:00Z",
          },
          %{
            "id" => 789,
            "title" => "three-changed",
            "updatedAt" => "2018-04-23T05:00:00Z",
          },
        ]
      }
    }
  end

end
