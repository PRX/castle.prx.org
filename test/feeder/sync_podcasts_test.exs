defmodule Feeder.SyncPodcastsTest do
  use Castle.HttpCase
  use Castle.TimeHelpers

  @feeder PrxAccess.Remote.host_to_url(Env.get(:feeder_host))
  @podcasts "#{@feeder}/api/v1/authorization/podcasts?per=200&since=1970-01-01"

  @root %PrxAccess.Resource{
    attributes: %{"userId" => "1234"},
    _links: %{
      "prx:podcasts" => %PrxAccess.Resource.Link{
        href: "/api/v1/authorization/podcasts{?page,per,zoom,since}"
      }
    },
    _embedded: %{},
    _url: "#{@feeder}/api/v1/authorization",
    _status: 200
  }

  setup do
    Memoize.Cache.get_or_run({Feeder.Api, :root, []}, fn -> {:ok, @root} end)
    []
  end

  test_with_http "updates nothing", %{@podcasts => %{}} do
    assert {:ok, 0, 0, 0} = Feeder.SyncPodcasts.sync()
  end

  test_with_http "creates and updates", %{@podcasts => updates_and_creates(3)} do
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

    assert {:ok, 1, 2, 0} = Feeder.SyncPodcasts.sync()
    assert Castle.Repo.get(Castle.Podcast, 123).title == "one-changed"
    assert Castle.Repo.get(Castle.Podcast, 456).title == "two"
    # updated_at stale
    assert Castle.Repo.get(Castle.Podcast, 789).title == "three"
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
