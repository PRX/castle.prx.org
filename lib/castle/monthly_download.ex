defmodule Castle.MonthlyDownload do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "monthly_downloads" do
    field :podcast_id, :integer
    field :episode_id, :binary_id
    field :month, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :episode_id, :month, :count])
    |> validate_required([:podcast_id, :episode_id, :month, :count])
  end

  def upsert!(download) do
    conflict = [set: [podcast_id: download.podcast_id, count: download.count]]
    target = [:episode_id, :month]
    Castle.Repo.insert!(download, on_conflict: conflict, conflict_target: target)
  end

  def upsert_all([]), do: 0
  def upsert_all(rows) when length(rows) > 5000 do
    Enum.chunk_every(rows, 5000) |> Enum.map(&upsert_all/1) |> Enum.sum()
  end
  def upsert_all(rows) do
    conflict = :replace_all
    target = [:episode_id, :month]
    Castle.Repo.insert_all Castle.MonthlyDownload, rows, on_conflict: conflict, conflict_target: target
    length(rows)
  end
end
