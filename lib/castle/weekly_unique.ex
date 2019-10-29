defmodule Castle.WeeklyUnique do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "weekly_uniques" do
    field :podcast_id, :integer
    field :week, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :week, :count])
    |> validate_required([:podcast_id, :week, :count])
  end

  def upsert_all([]), do: 0
  def upsert_all(rows) do
    Castle.Repo.insert_all Castle.WeeklyUnique, rows,
      on_conflict: :replace_all,
      conflict_target: [:podcast_id, :week]
    length(rows)
  end

end
