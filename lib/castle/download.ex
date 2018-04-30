defmodule Castle.Download do
  use Ecto.Schema
  import Ecto.Changeset

  schema "downloads" do
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
end
