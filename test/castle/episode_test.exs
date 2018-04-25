defmodule Castle.EpisodeTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Episode

  test "gets a null max updated_at timestamp" do
    assert max_updated_at() == nil
  end

  test "gets the max updated_at timestamp" do
    insert!(%Castle.Episode{id: "a", podcast_id: 1, updated_at: get_dtim("2018-04-25T04:00:00Z")})
    insert!(%Castle.Episode{id: "b", podcast_id: 1, updated_at: get_dtim("2018-04-25T02:00:00Z")})
    insert!(%Castle.Episode{id: "c", podcast_id: 1, updated_at: get_dtim("2018-04-25T18:00:00Z")})
    assert_time max_updated_at(), "2018-04-25T18:00:00Z"
  end

  test "gets the max updated_at for episodes in a podcast" do
    insert!(%Castle.Episode{id: "a", podcast_id: 1, updated_at: get_dtim("2018-04-25T04:00:00Z")})
    insert!(%Castle.Episode{id: "b", podcast_id: 2, updated_at: get_dtim("2018-04-25T02:00:00Z")})
    insert!(%Castle.Episode{id: "c", podcast_id: 2, updated_at: get_dtim("2018-04-25T18:00:00Z")})
    assert_time max_updated_at(1), "2018-04-25T04:00:00Z"
  end

  test "creates from a feeder doc" do
    from_feeder(%{
      "id" => "abc",
      "title" => "hello",
      "subtitle" => "world",
      "createdAt" => "2018-04-25T04:00:00.129Z",
      "updatedAt" => "2018-04-25T05:00:00Z",
      "publishedAt" => "2018-04-25T04:30:00Z",
      "images" => [
        %{"url" => "http://foo.bar/image1.jpg"},
        %{"url" => "http://foo.bar/image2.jpg"},
      ],
      "_links" => %{
        "prx:podcast" => %{"href" => "/api/v1/podcasts/123"}
      }
    })
    assert episode = get(Castle.Episode, "abc")
    assert episode.podcast_id == 123
    assert episode.title == "hello"
    assert episode.subtitle == "world"
    assert episode.image_url == "http://foo.bar/image1.jpg"
    assert_time episode.created_at, "2018-04-25T04:00:00.129000Z"
    assert_time episode.updated_at, "2018-04-25T05:00:00Z"
    assert_time episode.published_at, "2018-04-25T04:30:00Z"
  end

  test "updates from a feeder doc" do
    original = insert!(%Castle.Episode{id: "abc", podcast_id: 1, title: "hello", updated_at: get_dtim("2018-04-25T04:00:00Z")})
    from_feeder(original, %{
      "id" => "abc",
      "title" => "world",
      "updatedAt" => "2018-04-25T05:00:00Z",
      "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/1"}}
    })
    assert episode = get(Castle.Episode, "abc")
    assert episode.title == "world"
    assert_time episode.updated_at, "2018-04-25T05:00:00Z"
  end

  test "ignores updates with an older timestamp" do
    original = insert!(%Castle.Episode{id: "abc", podcast_id: 1, title: "hello", updated_at: get_dtim("2018-04-25T04:00:00Z")})
    from_feeder(original, %{
      "id" => "abc",
      "title" => "world",
      "updatedAt" => "2018-04-25T03:00:00Z",
      "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/1"}}
    })
    assert episode = get(Castle.Episode, "abc")
    assert episode.title == "hello"
  end

  test "does not allow a null podcast" do
    assert_raise Postgrex.Error, ~r/null value in column "podcast_id"/i, fn ->
      from_feeder(%{"id" => "abc", "title" => "hello"})
    end
  end

  test "allows null images" do
    from_feeder(%{
      "id" => "abc",
      "images" => [],
      "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/1"}}
    })
    assert episode = get(Castle.Episode, "abc")
    assert episode.image_url == nil
  end
end
