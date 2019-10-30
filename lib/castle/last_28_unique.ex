defmodule Castle.Last28Unique do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "last_28_uniques" do
    field :podcast_id, :integer
    field :last_28, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :last_28, :count])
    |> validate_required([:podcast_id, :last_28, :count])
  end

  def upsert_all([]), do: 0
  def upsert_all(rows) do
    Castle.Repo.insert_all Castle.Last28Unique, rows,
      on_conflict: :replace_all,
      conflict_target: [:podcast_id, :last_28]
    length(rows)
  end

end
