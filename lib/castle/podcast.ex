defmodule Castle.Podcast do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :integer, autogenerate: false}

  schema "podcasts" do
    field :account_id, :integer
    field :title, :string
    field :subtitle, :string
    field :image_url, :string
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :published_at, :utc_datetime
  end

  @doc false
  def changeset(podcast, attrs) do
    podcast
    |> cast(attrs, [:account_id, :title, :subtitle, :image_url, :created_at, :updated_at, :published_at])
  end

  def max_updated_at do
    Castle.Repo.one(from p in Castle.Podcast, select: max(p.updated_at))
  end
end
