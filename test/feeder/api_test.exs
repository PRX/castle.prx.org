defmodule Feeder.ApiTest do
  use Castle.HttpCase

  @all "per=100&since=1970-01-01"
  @podcasts "https://feeder.prx.org/api/v1/podcasts"
  @episodes "https://feeder.prx.org/api/v1/episodes"
  @all_podcasts "#{@podcasts}?#{@all}"

  test_with_http "handles 404s", %{@all_podcasts => 404} do
    assert {:error, "got 404 from" <> _msg} = Feeder.Api.podcasts()
  end

  test_with_http "handles 5XXs", %{@all_podcasts => 503} do
    assert {:error, "got 503 from" <> _msg} = Feeder.Api.podcasts()
  end

  test_with_http "handles json decode errors", %{@all_podcasts => "foobar"} do
    assert {:error, "invalid json from" <> _msg} = Feeder.Api.podcasts()
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

  test_with_http "loads episodes since", %{"#{@episodes}?per=100&since=2018-04-01T00%3A00%3A00Z" => %{}} do
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
      p3 => mock_items(3, 13) # total changed, but it should pick this one
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
      p4 => mock_items(5, 244, "#{@podcasts}?page=dontfollowthislink"),
    }
  end

  defp mock_items(count, total, next_href \\ nil) do
    %{
      "count" => count,
      "total" => total,
      "_embedded" => %{"prx:items" => List.duplicate(%{"id" => 1234, "title" => "Podcast"}, count)},
      "_links" => next_link(next_href),
    }
  end

  defp next_link(nil), do: %{}
  defp next_link(href), do: %{"next" => %{"href" => href}}
end
