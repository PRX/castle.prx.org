defmodule Castle.HourlyDownload do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "hourly_downloads" do
    field :podcast_id, :integer
    field :episode_id, :binary_id
    field :dtim, :utc_datetime
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :episode_id, :dtim, :count])
    |> validate_required([:podcast_id, :episode_id, :dtim, :count])
  end

  def upsert(row), do: upsert_all([row])

  def upsert_all([]), do: 0
  def upsert_all(rows) when length(rows) > 5000 do
    Enum.chunk_every(rows, 5000)
    |> Enum.map(&upsert_all/1)
    |> Enum.sum()
  end
  def upsert_all(rows) do
    Castle.Repo.insert_all Castle.HourlyDownload, Enum.map(rows, &parse_row/1)
    length(rows)
  end

  def set_podcast_totals! do
    totals = "SELECT SUM(count) FROM hourly_downloads WHERE podcast_id = id"
    update = "UPDATE podcasts SET total_downloads = (#{totals})"
    result = Ecto.Adapters.SQL.query!(Castle.Repo, update, [])
    result.num_rows
  end

  def set_episode_totals! do
    totals = "SELECT SUM(count) FROM hourly_downloads WHERE episode_id = id"
    update = "UPDATE episodes SET total_downloads = (#{totals})"
    result = Ecto.Adapters.SQL.query!(Castle.Repo, update, [])
    result.num_rows
  end

  defp parse_row(%{podcast_id: id, episode_guid: guid, hour: hour, count: count}) do
    %{podcast_id: id, episode_id: guid, dtim: hour, count: count}
  end
  defp parse_row(row), do: row
end
