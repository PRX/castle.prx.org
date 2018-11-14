defmodule Castle.PodcastTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Podcast

  test "gets a null max updated_at timestamp" do
    assert max_updated_at() == nil
  end

  test "gets the max updated_at timestamp" do
    insert!(%Castle.Podcast{id: 1, account_id: 123, updated_at: get_dtim("2018-04-25T04:00:00Z")})
    insert!(%Castle.Podcast{id: 2, account_id: 456, updated_at: get_dtim("2018-04-25T02:00:00Z")})
    insert!(%Castle.Podcast{id: 3, account_id: 123, updated_at: get_dtim("2018-04-25T18:00:00Z")})
    assert_time max_updated_at(), "2018-04-25T18:00:00Z"
  end

  test "creates from a feeder doc" do
    from_feeder(%{
      "id" => 123,
      "prxAccountUri" => "/api/v1/accounts/456",
      "title" => "hello",
      "subtitle" => "world",
      "createdAt" => "2018-04-25T04:00:00.129Z",
      "updatedAt" => "2018-04-25T05:00:00Z",
      "publishedAt" => "2018-04-25T04:30:00Z",
      "itunesImage" => %{"url" => "http://foo.bar/itunes.jpg"},
      "feedImage" => %{"url" => "http://foo.bar/feed.jpg"},
    })
    assert podcast = get(Castle.Podcast, 123)
    assert podcast.account_id == 456
    assert podcast.title == "hello"
    assert podcast.subtitle == "world"
    assert podcast.image_url == "http://foo.bar/feed.jpg"
    assert_time podcast.created_at, "2018-04-25T04:00:00.129000Z"
    assert_time podcast.updated_at, "2018-04-25T05:00:00Z"
    assert_time podcast.published_at, "2018-04-25T04:30:00Z"
  end

  test "updates from a feeder doc" do
    original = insert!(%Castle.Podcast{id: 123, title: "hello", updated_at: get_dtim("2018-04-25T04:00:00Z")})
    from_feeder(original, %{"id" => 123, "title" => "world", "updatedAt" => "2018-04-25T05:00:00Z"})
    assert podcast = get(Castle.Podcast, 123)
    assert podcast.title == "world"
    assert_time podcast.updated_at, "2018-04-25T05:00:00Z"
  end

  test "ignores updates with an older timestamp" do
    original = insert!(%Castle.Podcast{id: 123, title: "hello", updated_at: get_dtim("2018-04-25T04:00:00Z")})
    from_feeder(original, %{"id" => 123, "title" => "world", "updatedAt" => "2018-04-25T03:00:00Z"})
    assert podcast = get(Castle.Podcast, 123)
    assert podcast.title == "hello"
  end

  test "allows null account" do
    from_feeder(%{"id" => 123, "title" => "hello"})
    assert podcast = get(Castle.Podcast, 123)
    assert podcast.account_id == nil
    assert podcast.title == "hello"
  end

  test "falls back to the itunes image" do
    from_feeder(%{"id" => 123, "itunesImage" => %{"url" => "http://foo.bar/itunes.jpg"}})
    assert podcast = get(Castle.Podcast, 123)
    assert podcast.image_url == "http://foo.bar/itunes.jpg"
  end

  test "gets recent podcasts for accounts" do
    insert!(%Castle.Podcast{id: 1, account_id: 123})
    insert!(%Castle.Podcast{id: 2, account_id: 456})
    insert!(%Castle.Podcast{id: 3, account_id: 123})
    podcasts = recent_query([123])
               |> Castle.Repo.all
    assert length(podcasts) == 2
    assert Enum.at(podcasts, 0).id == 1
    assert Enum.at(podcasts, 1).id == 3
  end

  test "gets total podcasts for accounts" do
    insert!(%Castle.Podcast{id: 1, account_id: 123})
    insert!(%Castle.Podcast{id: 2, account_id: 456})
    insert!(%Castle.Podcast{id: 3, account_id: 123})
    assert recent_query([]) |> total == 0
    assert recent_query([123]) |> total == 2
    assert recent_query([123, 456]) |> total == 3
  end

  test "podcast title and subtitle are searchable with keyword query" do
    insert!(%Castle.Podcast{id: 1, account_id: 1, title: "A quick fox"})
    insert!(%Castle.Podcast{id: 2, account_id: 1, subtitle: "jumps over"})
    insert!(%Castle.Podcast{id: 3, account_id: 1, title: "the sleeping dog"})

    q = recent_query([1])
    assert (q |> CastleWeb.Search.filter_title_search("dog") |> Castle.Repo.all |> Enum.map(fn e -> e.id end))
      == [3]
    assert (q |> CastleWeb.Search.filter_title_search("quick jumps dog") |> Castle.Repo.all |> Enum.map(fn e -> e.id end))
      == [1, 2, 3]

  end
end
