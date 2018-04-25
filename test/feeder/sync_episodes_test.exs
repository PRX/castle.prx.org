defmodule Feeder.SyncEpisodesTest do
  use Castle.HttpCase
  use Castle.TimeHelpers

  @episodes "https://feeder.prx.org/api/v1/episodes?per=100&since=1970-01-01"

  test_with_http "updates nothing", %{@episodes => %{}} do
    assert {:ok, 0, 0, 0} = Feeder.SyncEpisodes.sync()
  end

  test_with_http "creates and updates", %{@episodes => updates_and_creates(3)} do
    Castle.Repo.insert!(%Castle.Episode{id: "def", title: "two", podcast_id: 1, updated_at: get_dtim("2018-04-25T04:00:00Z")})
    assert {:ok, 2, 1, 0} = Feeder.SyncEpisodes.sync()
    assert Castle.Repo.get(Castle.Episode, "abc").title == "one"
    assert Castle.Repo.get(Castle.Episode, "def").title == "two-changed"
    assert Castle.Repo.get(Castle.Episode, "ghi").title == "three"
  end

  test_with_http "has remaining items to process", %{@episodes => updates_and_creates(10)} do
    assert {:ok, 3, 0, 7} = Feeder.SyncEpisodes.sync()
  end

  defp updates_and_creates(total) do
    %{
      "total" => total,
      "_embedded" => %{
        "prx:items" => [
          %{
            "id" => "abc",
            "title" => "one",
            "updatedAt" => "2018-04-25T05:00:00Z",
            "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/123"}}
          },
          %{
            "id" => "def",
            "title" => "two-changed",
            "updatedAt" => "2018-04-25T05:00:00Z",
            "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/123"}}
          },
          %{
            "id" => "ghi",
            "title" => "three",
            "updatedAt" => "2018-04-25T05:00:00Z",
            "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/123"}}
          },
        ]
      }
    }
  end

end
