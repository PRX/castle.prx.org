defmodule Castle.DailyAgent do
  use Ecto.Schema
  use Castle.Model.Partitioned
  import Ecto.Changeset

  @primary_key false
  @partition_on :day
  @partition_unique [:episode_id, :agent_name_id, :agent_type_id, :agent_os_id, :day]

  schema "daily_agents" do
    field :podcast_id, :integer
    field :episode_id, :binary_id
    field :agent_name_id, :integer
    field :agent_type_id, :integer
    field :agent_os_id, :integer
    field :day, :date
    field :count, :integer
  end

  @doc false
  def changeset(download, attrs) do
    download
    |> cast(attrs, [:podcast_id, :episode_id, :agent_name_id, :agent_type_id, :agent_os_id, :day, :count])
    |> validate_required([:podcast_id, :episode_id, :agent_name_id, :agent_type_id, :agent_os_id, :day, :count])
  end
end
