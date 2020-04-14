defmodule Castle.Repo.Migrations.AddEpisodeMetadata do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add(:released_at, :utc_datetime)
      add(:segment_count, :integer)
      add(:audio_version, :string)
    end
  end
end
