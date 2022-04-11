defmodule Castle.Podcast do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :integer, autogenerate: false}

  schema "podcasts" do
    field(:account_id, :integer)
    field(:title, :string)
    field(:subtitle, :string)
    field(:image_url, :string)
    field(:created_at, :utc_datetime)
    field(:updated_at, :utc_datetime)
    field(:deleted_at, :utc_datetime)
    field(:published_at, :utc_datetime)
  end

  def changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [
      :account_id,
      :title,
      :subtitle,
      :image_url,
      :created_at,
      :updated_at,
      :deleted_at,
      :published_at
    ])
  end

  def all do
    Castle.Repo.all(Castle.Podcast, order_by: [asc: :id])
  end

  def recent_query(accounts) do
    from(p in Castle.Podcast, where: p.account_id in ^accounts, order_by: [asc: :title])
  end

  def undeleted(queryable) do
    from(r in queryable, where: is_nil(r.deleted_at))
  end

  def total(queryable) do
    Castle.Repo.one(from(r in subquery(queryable), select: count(r.id)))
  end

  def max_updated_at do
    Castle.Repo.one(from(p in Castle.Podcast, select: max(p.updated_at)))
  end

  def from_feeder(doc) do
    struct!(Castle.Podcast, parse_feeder(doc)) |> Castle.Repo.insert!()
  end

  def from_feeder(podcast, doc) do
    changes = parse_feeder(doc)

    if Timex.compare(changes.updated_at, podcast.updated_at) >= 0 do
      changeset(podcast, changes) |> Castle.Repo.update!()
    end
  end

  defp parse_feeder(doc) do
    %{
      id: doc["id"],
      account_id: account_id(doc["prxAccountUri"]),
      title: doc["title"],
      subtitle: doc["subtitle"],
      image_url: image_url(doc),
      created_at: parse_dtim(doc["createdAt"]),
      updated_at: parse_dtim(doc["updatedAt"]),
      deleted_at: parse_dtim(doc["deletedAt"]),
      published_at: parse_dtim(doc["publishedAt"])
    }
  end

  defp account_id("/api/v1/accounts/" <> id), do: String.to_integer(id)
  defp account_id(_any), do: nil

  defp image_url(%{"feedImage" => %{"url" => url}}), do: url
  defp image_url(%{"itunesImage" => %{"url" => url}}), do: url
  defp image_url(_any), do: nil

  defp parse_dtim(nil), do: nil

  defp parse_dtim(dtim_str) do
    {:ok, dtim} = Timex.parse(dtim_str, "{ISO:Extended:Z}")
    DateTime.truncate(dtim, :second)
  end
end
