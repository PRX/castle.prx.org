defmodule Castle.HourlyDownload do
  use Ecto.Schema
  use Castle.Model.Partitioned
  import Ecto.Changeset

  @primary_key false
  @partition_on :dtim
  @partition_unique [:episode_id, :dtim]

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
end
