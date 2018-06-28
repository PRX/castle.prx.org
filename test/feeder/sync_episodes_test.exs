defmodule Feeder.SyncEpisodesTest do
  use Castle.HttpCase
  use Castle.TimeHelpers

  @episodes "https://feeder.prx.org/api/v1/episodes?per=100&since=1970-01-01"
  @id1 UUID.uuid4()
  @id2 UUID.uuid4()
  @id3 UUID.uuid4()

  test_with_http "updates nothing", %{@episodes => %{}} do
    assert {:ok, 0, 0, 0} = Feeder.SyncEpisodes.sync()
  end

  test_with_http "creates and updates", %{@episodes => updates_and_creates(3)} do
    Castle.Repo.insert!(%Castle.Episode{id: @id2, title: "two", podcast_id: 1, updated_at: get_dtim("2018-04-25T04:00:00Z")})
    assert {:ok, 2, 1, 0} = Feeder.SyncEpisodes.sync()
    assert Castle.Repo.get(Castle.Episode, @id1).title == "one"
    assert Castle.Repo.get(Castle.Episode, @id2).title == "two-changed"
    assert Castle.Repo.get(Castle.Episode, @id3).title == "three"
  end

  test_with_http "has remaining items to process", %{@episodes => updates_and_creates(10)} do
    assert {:ok, 3, 0, 7} = Feeder.SyncEpisodes.sync()
  end

  test_with_http "skips episodes with no podcast", %{@episodes => updates_and_creates(10, true)} do
    assert {:ok, 2, 0, 8} = Feeder.SyncEpisodes.sync()
  end

  defp updates_and_creates(total, skip_podcast \\ false) do
    %{
      "total" => total,
      "_embedded" => %{
        "prx:items" => [
          %{
            "id" => @id1,
            "title" => "one",
            "updatedAt" => "2018-04-25T05:00:00Z",
            "_links" => podcast_link(123, false)
          },
          %{
            "id" => @id2,
            "title" => "two-changed",
            "updatedAt" => "2018-04-25T05:00:00Z",
            "_links" => podcast_link(456, skip_podcast)
          },
          %{
            "id" => @id3,
            "title" => "three",
            "updatedAt" => "2018-04-25T05:00:00Z",
            "_links" => podcast_link(789, false)
          },
        ]
      }
    }
  end

  defp podcast_link(_id, true), do: %{}
  defp podcast_link(id, false) do
    %{"prx:podcast" => %{"href" => "/api/v1/podcasts/#{id}"}}
  end

end
