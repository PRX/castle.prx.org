defmodule Castle.MonthlyUnique do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "monthly_uniques" do
    field :podcast_id, :integer
    field :month, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :month, :count])
    |> validate_required([:podcast_id, :month, :count])
  end

  def upsert_all([]), do: 0
  def upsert_all(rows) do
    Castle.Repo.insert_all Castle.MonthlyUnique, rows,
      on_conflict: :replace_all,
      conflict_target: [:podcast_id, :month]
    length(rows)
  end

end
