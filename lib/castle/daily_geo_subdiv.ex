defmodule Castle.DailyGeoSubdiv do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "daily_geo_subdivs" do
    field :podcast_id, :integer
    field :episode_id, :binary_id
    field :country_iso_code, :string
    field :subdivision_1_iso_code, :string
    field :day, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :episode_id, :country_iso_code, :subdivision_1_iso_code, :day, :count])
    |> validate_required([:podcast_id, :episode_id, :country_iso_code, :subdivision_1_iso_code, :day, :count])
  end

  def upsert(row), do: upsert_all([row])

  def upsert_all([]), do: 0
  def upsert_all(rows) when length(rows) > 5000 do
    Enum.chunk_every(rows, 5000)
    |> Enum.map(&upsert_all/1)
    |> Enum.sum()
  end
  def upsert_all(rows) do
    Castle.Repo.insert_all Castle.DailyGeoSubdiv, rows
    length(rows)
  end

  # defp parse_row(%{podcast_id: id, episode_guid: guid, hour: hour, count: count}) do
  #   %{podcast_id: id, episode_id: guid, dtim: hour, count: count}
  # end
  # defp parse_row(row), do: row
end
