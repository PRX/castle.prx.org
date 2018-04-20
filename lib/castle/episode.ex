defmodule Castle.Episode do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:guid, :string, autogenerate: false}

  schema "episodes" do

    field :podcast_id, :integer
    field :name, :string
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
    field :published_at, :utc_datetime
  end

  @doc false
  def changeset(episode, attrs) do
    episode
    |> cast(attrs, [:podcast_id, :name, :created_at, :updated_at, :published_at])
    |> validate_required([:podcast_id, :name])
  end


  def max_updated_at() do
    Castle.Repo.one(from e in Castle.Episode, select: max(e.updated_at))
  end
  def max_updated_at(pid) do
    Castle.Repo.one(from e in Castle.Episode, select: max(e.updated_at), where: e.podcast_id == ^pid)
  end
end
