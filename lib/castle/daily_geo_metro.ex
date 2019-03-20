defmodule Castle.DailyGeoMetro do
  use Ecto.Schema
  use Castle.Model.Partitioned
  import Ecto.Changeset

  @primary_key false
  @partition_on :day
  @partition_unique [:episode_id, :metro_code, :day]

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
end
