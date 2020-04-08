defmodule Feeder.ApiTest do
  use Castle.HttpCase

  @feeder PrxAccess.Remote.host_to_url(Env.get(:feeder_host))
  @all "per=100&since=1970-01-01"
  @podcasts "#{@feeder}/api/v1/authorization/podcasts"
  @episodes "#{@feeder}/api/v1/authorization/episodes"
  @all_podcasts "#{@podcasts}?#{@all}"

  @mocks %{
    "#{@feeder}/api/v1" => %{"id" => "root-doc"},
    "#{@feeder}/api/v1/authorization" => %{
      "id" => "auth-doc",
      "_links" => %{
        "prx:episode" => %{href: "/api/v1/authorization/episodes/{id}{?zoom}"},
        "prx:episodes" => %{href: "/api/v1/authorization/episodes{?page,per,zoom,since}"},
        "prx:podcast" => %{href: "/api/v1/authorization/podcasts/{id}{?zoom}"},
        "prx:podcasts" => %{href: "/api/v1/authorization/podcasts{?page,per,zoom,since}"}
      }
    }
  }

  test_with_http "gets the root", @mocks do
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert root._token == "mock-token"
    assert root._url == "#{@feeder}/api/v1/authorization"
    assert root.attributes == %{"id" => "auth-doc"}
  end

  test_with_http "handles 404s", Map.put(@mocks, @all_podcasts, 404) do
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert {:error, %PrxAccess.Error{} = err} = Feeder.Api.podcasts(root)
    assert err.message =~ "Got 404 for "
    assert err.status == 404
  end

  test_with_http "handles 5XXs", Map.put(@mocks, @all_podcasts, 503) do
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert {:error, %PrxAccess.Error{} = err} = Feeder.Api.podcasts(root)
    assert err.message =~ "Got 503 for "
    assert err.status == 503
  end

  test_with_http "handles json decode errors", Map.put(@mocks, @all_podcasts, "not-json") do
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert {:error, %PrxAccess.Error{} = err} = Feeder.Api.podcasts(root)
    assert err.message =~ "JSON decode error"
    assert err.status == 200
  end

  test_with_http "gets empty array of podcasts", Map.put(@mocks, @all_podcasts, %{}) do
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert {:ok, 0, []} = Feeder.Api.podcasts(root)
  end

  test_with_http "gets single page of podcasts", mock_podcast_pages(1) do
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert {:ok, 5, items} = Feeder.Api.podcasts(root)
    assert length(items) == 5
    assert hd(items)["id"] == 1234
    assert hd(items)["title"] == "Podcast"
  end

  test_with_http "gets multiple pages of podcasts", mock_podcast_pages(3) do
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert {:ok, 13, items} = Feeder.Api.podcasts(root)
    assert length(items) == 13
    assert hd(items)["id"] == 1234
    assert hd(items)["title"] == "Podcast"
  end

  test_with_http "partially loads podcasts when there are too dang many", mock_podcast_pages(5) do
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert {:partial, 244, items} = Feeder.Api.podcasts(root)
    assert length(items) == 20
    assert hd(items)["id"] == 1234
    assert hd(items)["title"] == "Podcast"
  end

  test_with_http "loads episodes since", mock_episodes_since("2018-04-01T00%3A00%3A00Z") do
    {:ok, dtim} = Timex.parse("2018-04-01", "{YYYY}-{0M}-{0D}")
    assert {:ok, root} = Feeder.Api.root("mock-token")
    assert {:ok, 0, []} = Feeder.Api.episodes(root, dtim)
  end

  defp mock_episodes_since(date_str) do
    Map.put(@mocks, "#{@episodes}?per=100&since=#{date_str}", %{})
  end

  defp mock_podcast_pages(1) do
    %{@all_podcasts => mock_items(5, 5)}
    |> Map.merge(@mocks)
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
    |> Map.merge(@mocks)
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
    |> Map.merge(@mocks)
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
