defmodule Feeder.ApiTest do
  use Castle.HttpCase
  alias PrxAccess.Resource.Link

  @feeder PrxAccess.Remote.host_to_url(Env.get(:feeder_host))
  @all "per=200&since=1970-01-01"
  @podcasts "#{@feeder}/api/v1/authorization/podcasts"
  @episodes "#{@feeder}/api/v1/authorization/episodes"
  @all_podcasts "#{@podcasts}?#{@all}"

  @links %{
    "prx:episodes" => %Link{href: "/api/v1/authorization/episodes{?page,per,zoom,since}"},
    "prx:podcasts" => %Link{href: "/api/v1/authorization/podcasts{?page,per,zoom,since}"}
  }
  @root %PrxAccess.Resource{
    attributes: %{"userId" => "1234"},
    _links: @links,
    _embedded: %{},
    _url: "#{@feeder}/api/v1/authorization",
    _status: 200
  }

  setup do
    Memoize.Cache.get_or_run({Feeder.Api, :root, []}, fn -> {:ok, @root} end)
    []
  end

  test "gets the root" do
    assert {:ok, root} = Feeder.Api.root()
    assert root._url == "#{@feeder}/api/v1/authorization"
    assert root.attributes == %{"userId" => "1234"}
  end

  test_with_http "handles 404s", %{@all_podcasts => 404} do
    assert {:error, %PrxAccess.Error{} = err} = Feeder.Api.podcasts()
    assert err.message =~ "Got 404 for "
    assert err.status == 404
  end

  test_with_http "handles 5XXs", %{@all_podcasts => 503} do
    assert {:error, %PrxAccess.Error{} = err} = Feeder.Api.podcasts()
    assert err.message =~ "Got 503 for "
    assert err.status == 503
  end

  test_with_http "handles json decode errors", %{@all_podcasts => "not-json"} do
    assert {:error, %PrxAccess.Error{} = err} = Feeder.Api.podcasts()
    assert err.message =~ "JSON decode error"
    assert err.status == 200
  end

  test_with_http "gets empty array of podcasts", %{@all_podcasts => %{}} do
    assert {:ok, 0, []} = Feeder.Api.podcasts()
  end

  test_with_http "gets single page of podcasts", mock_podcast_pages(1) do
    assert {:ok, 5, items} = Feeder.Api.podcasts()
    assert length(items) == 5
    assert hd(items)["id"] == 1234
    assert hd(items)["title"] == "Podcast"
  end

  test_with_http "gets multiple pages of podcasts", mock_podcast_pages(3) do
    assert {:ok, 13, items} = Feeder.Api.podcasts()
    assert length(items) == 13
    assert hd(items)["id"] == 1234
    assert hd(items)["title"] == "Podcast"
  end

  test_with_http "partially loads podcasts when there are too dang many", mock_podcast_pages(5) do
    assert {:partial, 244, items} = Feeder.Api.podcasts()
    assert length(items) == 20
    assert hd(items)["id"] == 1234
    assert hd(items)["title"] == "Podcast"
  end

  test_with_http "loads episodes since", %{
    "#{@episodes}?per=200&since=2018-04-01T00%3A00%3A00Z" => %{}
  } do
    {:ok, dtim} = Timex.parse("2018-04-01", "{YYYY}-{0M}-{0D}")
    assert {:ok, 0, []} = Feeder.Api.episodes(dtim)
  end

  defp mock_podcast_pages(1) do
    %{@all_podcasts => mock_items(5, 5)}
  end

  defp mock_podcast_pages(3) do
    p2 = "#{@podcasts}?page=2&#{@all}"
    p3 = "#{@podcasts}?page=3&#{@all}"

    %{
      @all_podcasts => mock_items(5, 12, p2),
      p2 => mock_items(5, 12, p3),
      # total changed, but it should pick this one
      p3 => mock_items(3, 13)
    }
  end

  defp mock_podcast_pages(5) do
    p2 = "#{@podcasts}?page=2&#{@all}"
    p3 = "#{@podcasts}?page=3&#{@all}"
    p4 = "#{@podcasts}?page=4&#{@all}"

    %{
      @all_podcasts => mock_items(5, 244, p2),
      p2 => mock_items(5, 244, p3),
      p3 => mock_items(5, 244, p4),
      p4 => mock_items(5, 244, "#{@podcasts}?page=dontfollowthislink")
    }
  end

  defp mock_items(count, total, next_href \\ nil) do
    %{
      "count" => count,
      "total" => total,
      "_embedded" => %{
        "prx:items" => List.duplicate(%{"id" => 1234, "title" => "Podcast"}, count)
      },
      "_links" => next_link(next_href)
    }
  end

  defp next_link(nil), do: %{}
  defp next_link(href), do: %{"next" => %{"href" => href}}
end
