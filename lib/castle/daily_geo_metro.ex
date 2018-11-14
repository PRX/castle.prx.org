defmodule Castle.DailyGeoMetro do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "daily_geo_metros" do
    field :podcast_id, :integer
    field :episode_id, :binary_id
    field :metro_code, :integer
    field :day, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :episode_id, :metro_code, :day, :count])
    |> validate_required([:podcast_id, :episode_id, :metro_code, :day, :count])
  end

  def upsert(row), do: upsert_all([row])

  def upsert_all([]), do: 0
  def upsert_all(rows) when length(rows) > 5000 do
    Enum.chunk_every(rows, 5000)
    |> Enum.map(&upsert_all/1)
    |> Enum.sum()
  end
  def upsert_all(rows) do
    Castle.Repo.insert_all Castle.DailyGeoMetro, rows, on_conflict: :replace_all,
      conflict_target: [:episode_id, :metro_code, :day]
    length(rows)
  end
end
