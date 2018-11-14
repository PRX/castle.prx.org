defmodule Castle.DailyGeoSubdiv do
  use Ecto.Schema
  use Castle.Model.Partitioned
  import Ecto.Changeset

  @primary_key false
  @partition_on :day
  @partition_unique [:episode_id, :country_iso_code, :subdivision_1_iso_code, :day]

  schema "daily_geo_subdivs" do
    field :podcast_id, :integer
    field :episode_id, :binary_id
    field :country_iso_code, Castle.Model.TrimmedString
    field :subdivision_1_iso_code, Castle.Model.TrimmedString
    field :day, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :episode_id, :country_iso_code, :subdivision_1_iso_code, :day, :count])
    |> validate_required([:podcast_id, :episode_id, :country_iso_code, :subdivision_1_iso_code, :day, :count])
  end
end
