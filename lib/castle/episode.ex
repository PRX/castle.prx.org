defmodule Castle.Episode do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: false}
  @foreign_key_type :binary_id

  schema "episodes" do
    field(:podcast_id, :integer)
    field(:guid, :string)
    field(:title, :string)
    field(:subtitle, :string)
    field(:image_url, :string)
    field(:created_at, :utc_datetime)
    field(:updated_at, :utc_datetime)
    field(:deleted_at, :utc_datetime)
    field(:published_at, :utc_datetime)
    field(:released_at, :utc_datetime)
    field(:segment_count, :integer)
    field(:audio_version, :string)
    field(:categories, {:array, :string})
    field(:feed_slugs, {:array, :string})
    field(:season_number, :integer)
    field(:episode_number, :integer)
  end

  @doc false
  def changeset(episode, attrs) do
    episode
    |> cast(attrs, [
      :podcast_id,
      :guid,
      :title,
      :subtitle,
      :image_url,
      :created_at,
      :updated_at,
      :deleted_at,
      :published_at,
      :released_at,
      :segment_count,
      :audio_version,
      :categories,
      :feed_slugs,
      :season_number,
      :episode_number
    ])
    |> validate_required([:podcast_id])
  end

  def all do
    Castle.Repo.all(Castle.Episode, order_by: [asc: :id])
  end

  def recent_query(pid) when is_integer(pid) do
    from(e in Castle.Episode,
      where: e.podcast_id == ^pid and e.published_at <= ^Timex.now(),
      order_by: [desc: :published_at]
    )
  end

  def recent_query(accounts) when is_list(accounts) do
    podcast_query =
      subquery(
        from(p in Castle.Podcast,
          select: %{id: p.id, account_id: p.account_id}
        )
      )

    from(e in Castle.Episode,
      join: p in ^podcast_query,
      where:
        e.podcast_id == p.id and p.account_id in ^accounts and e.published_at <= ^Timex.now(),
      order_by: [desc: :published_at]
    )
  end

  def undeleted(queryable) do
    from(r in queryable, where: is_nil(r.deleted_at))
  end

  def total(queryable) do
    Castle.Repo.one(from(r in subquery(queryable), select: count(r.id)))
  end

  def max_updated_at() do
    Castle.Repo.one(from(e in Castle.Episode, select: max(e.updated_at)))
  end

  def max_updated_at(pid) do
    Castle.Repo.one(
      from(e in Castle.Episode, select: max(e.updated_at), where: e.podcast_id == ^pid)
    )
  end

  def from_feeder(doc) do
    struct!(Castle.Episode, parse_feeder(doc)) |> Castle.Repo.insert!()
  end

  def from_feeder(episode, doc) do
    changes = parse_feeder(doc)

    if Timex.compare(changes.updated_at, episode.updated_at) >= 0 do
      changeset(episode, changes) |> Castle.Repo.update!()
    end
  end

  defp parse_feeder(doc) do
    %{
      id: doc["id"],
      podcast_id: podcast_id(doc["_links"]),
      guid: doc["guid"],
      title: doc["title"],
      subtitle: doc["subtitle"],
      image_url: image_url(doc),
      created_at: parse_dtim(doc["createdAt"]),
      updated_at: parse_dtim(doc["updatedAt"]),
      deleted_at: parse_dtim(doc["deletedAt"]),
      published_at: parse_dtim(doc["publishedAt"]),
      released_at: parse_dtim(doc["releasedAt"]),
      segment_count: doc["segmentCount"],
      audio_version: doc["audioVersion"],
      categories: doc["categories"],
      feed_slugs: doc["feedSlugs"],
      season_number: doc["seasonNumber"],
      episode_number: doc["episodeNumber"]
    }
  end

  defp podcast_id(%{"prx:podcast" => link}) do
    case link do
      %{"href" => "/api/v1/podcasts/" <> id} -> String.to_integer(id)
      %{href: "/api/v1/podcasts/" <> id} -> String.to_integer(id)
      _ -> nil
    end
  end

  defp podcast_id(_any), do: nil

  defp image_url(%{"image" => %{"href" => href}}), do: href
  defp image_url(_any), do: nil

  defp parse_dtim(nil), do: nil

  defp parse_dtim(dtim_str) do
    {:ok, dtim} = Timex.parse(dtim_str, "{ISO:Extended:Z}")
    DateTime.truncate(dtim, :second)
  end
end
