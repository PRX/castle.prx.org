defmodule Castle.EpisodeTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.Episode

  @id1 UUID.uuid4()
  @id2 UUID.uuid4()
  @id3 UUID.uuid4()
  @id4 UUID.uuid4()

  test "gets a null max updated_at timestamp" do
    assert max_updated_at() == nil
  end

  test "gets the max updated_at timestamp" do
    insert_published!(id: @id1, podcast_id: 1, updated_at: get_dtim("2018-04-25T04:00:00Z"))
    insert_published!(id: @id2, podcast_id: 1, updated_at: get_dtim("2018-04-25T02:00:00Z"))
    insert_published!(id: @id3, podcast_id: 1, updated_at: get_dtim("2018-04-25T18:00:00Z"))

    assert_time(max_updated_at(), "2018-04-25T18:00:00Z")
  end

  test "gets the max updated_at for episodes in a podcast" do
    insert_published!(id: @id1, podcast_id: 1, updated_at: get_dtim("2018-04-25T04:00:00Z"))
    insert_published!(id: @id2, podcast_id: 2, updated_at: get_dtim("2018-04-25T02:00:00Z"))
    insert_published!(id: @id3, podcast_id: 2, updated_at: get_dtim("2018-04-25T18:00:00Z"))

    assert_time(max_updated_at(1), "2018-04-25T04:00:00Z")
  end

  test "creates from a feeder doc" do
    from_feeder(%{
      "id" => @id1,
      "guid" => "some-guid",
      "title" => "hello",
      "subtitle" => "world",
      "createdAt" => "2018-04-25T04:00:00.129Z",
      "updatedAt" => "2018-04-25T05:00:00Z",
      "deletedAt" => "2018-04-25T05:00:01Z",
      "publishedAt" => "2018-04-25T04:30:00Z",
      "releasedAt" => "2018-04-25T04:30:01Z",
      "segmentCount" => 2,
      "audioVersion" => "my-version",
      "image" => %{"href" => "http://foo.bar/image1.jpg"},
      "_links" => %{
        "prx:podcast" => %{"href" => "/api/v1/podcasts/123"}
      },
      "categories" => [
        "some",
        "tag"
      ]
    })

    assert episode = get(Castle.Episode, @id1)
    assert episode.podcast_id == 123
    assert episode.guid == "some-guid"
    assert episode.title == "hello"
    assert episode.subtitle == "world"
    assert episode.image_url == "http://foo.bar/image1.jpg"
    assert_time(episode.created_at, "2018-04-25T04:00:00Z")
    assert_time(episode.updated_at, "2018-04-25T05:00:00Z")
    assert_time(episode.deleted_at, "2018-04-25T05:00:01Z")
    assert_time(episode.published_at, "2018-04-25T04:30:00Z")
    assert_time(episode.released_at, "2018-04-25T04:30:01Z")
    assert episode.segment_count == 2
    assert episode.audio_version == "my-version"
    assert episode.keywords == ["some", "tag"]
  end

  test "updates from a feeder doc" do
    original =
      insert!(%Castle.Episode{
        id: @id1,
        podcast_id: 1,
        title: "hello",
        updated_at: get_dtim("2018-04-25T04:00:00Z")
      })

    from_feeder(original, %{
      "id" => @id1,
      "title" => "world",
      "updatedAt" => "2018-04-25T05:00:00Z",
      "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/1"}}
    })

    assert episode = get(Castle.Episode, @id1)
    assert episode.title == "world"
    assert_time(episode.updated_at, "2018-04-25T05:00:00Z")
  end

  test "ignores updates with an older timestamp" do
    original =
      insert!(%Castle.Episode{
        id: @id1,
        podcast_id: 1,
        title: "hello",
        updated_at: get_dtim("2018-04-25T04:00:00Z")
      })

    from_feeder(original, %{
      "id" => @id1,
      "title" => "world",
      "updatedAt" => "2018-04-25T03:00:00Z",
      "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/1"}}
    })

    assert episode = get(Castle.Episode, @id1)
    assert episode.title == "hello"
  end

  test "does not allow a null podcast" do
    assert_raise Postgrex.Error, ~r/null value in column "podcast_id"/i, fn ->
      from_feeder(%{"id" => @id1, "title" => "hello"})
    end
  end

  test "allows null images" do
    from_feeder(%{
      "id" => @id1,
      "images" => [],
      "_links" => %{"prx:podcast" => %{"href" => "/api/v1/podcasts/1"}}
    })

    assert episode = get(Castle.Episode, @id1)
    assert episode.image_url == nil
  end

  test "gets recent episodes for podcast" do
    insert_published!(id: @id1, podcast_id: 1)
    insert_published!(id: @id2, podcast_id: 2)
    insert_published!(id: @id3, podcast_id: 1)
    insert_unpublished!(id: @id4, podcast_id: 1)

    assert recent_query(1)
           |> Castle.Repo.all()
           |> Enum.map(fn e -> e.id end)
           |> Enum.sort() == Enum.sort([@id1, @id3])
  end

  test "gets recent episodes for accounts" do
    insert!(%Castle.Podcast{id: 1, account_id: 123})
    insert!(%Castle.Podcast{id: 2, account_id: 456})
    insert_published!(id: @id1, podcast_id: 1)
    insert_published!(id: @id2, podcast_id: 2)
    insert_published!(id: @id3, podcast_id: 1)
    insert_unpublished!(id: @id4, podcast_id: 1)

    assert recent_query([123])
           |> Castle.Repo.all()
           |> Enum.map(fn e -> e.id end)
           |> Enum.sort() == Enum.sort([@id1, @id3])
  end

  test "gets total episodes for podcast" do
    insert_published!(id: @id1, podcast_id: 1)
    insert_published!(id: @id2, podcast_id: 2)
    insert_published!(id: @id3, podcast_id: 1)
    insert_unpublished!(id: @id4, podcast_id: 1)
    assert total(recent_query(1)) == 2
    assert total(recent_query(2)) == 1
    assert total(recent_query(3)) == 0
  end

  test "gets total episodes for accounts" do
    insert!(%Castle.Podcast{id: 1, account_id: 123})
    insert!(%Castle.Podcast{id: 2, account_id: 456})
    insert_published!(id: @id1, podcast_id: 1)
    insert_published!(id: @id2, podcast_id: 2)
    insert_published!(id: @id3, podcast_id: 1)

    assert total(recent_query([])) == 0
    assert total(recent_query([123])) == 2
    assert total(recent_query([123, 456])) == 3
  end

  test "episodes are paginateable with CastleWeb interface" do
    insert_published!(id: @id1, podcast_id: 1)
    insert_published!(id: @id2, podcast_id: 1)
    insert_published!(id: @id3, podcast_id: 1)

    eps_ct =
      recent_query(1)
      |> CastleWeb.Paging.paginated_results(2, 1)
      |> Enum.count()

    assert eps_ct == 2
  end

  test "episodes title and subtitle are searchable with keyword query" do
    insert_published!(id: @id1, podcast_id: 1, title: "test bar A quick fox")
    insert_published!(id: @id2, podcast_id: 1, subtitle: "test foo jumps over")
    insert_published!(id: @id3, podcast_id: 1, title: "test foo the sleeping dog")

    assert Castle.Repo.all(from(e in Castle.Episode)) |> Enum.count() == 3

    assert recent_query(1)
           |> CastleWeb.Search.filter_title_search("dog")
           |> Castle.Repo.all()
           |> Enum.map(fn e -> e.id end)
           |> Enum.sort() == [@id3]

    assert recent_query(1)
           |> CastleWeb.Search.filter_title_search("test foo")
           |> Castle.Repo.all()
           |> Enum.map(fn e -> e.id end)
           |> Enum.sort() == [@id2, @id3] |> Enum.sort()
  end

  defp insert_published!(props) do
    struct(Castle.Episode, props) |> Map.put(:published_at, hours_from_now(-1)) |> insert!()
  end

  defp insert_unpublished!(props) do
    struct(Castle.Episode, props) |> Map.put(:published_at, hours_from_now(1)) |> insert!()
  end

  defp hours_from_now(hours) do
    Timex.shift(Timex.now(), hours: hours) |> DateTime.truncate(:second)
  end
end
