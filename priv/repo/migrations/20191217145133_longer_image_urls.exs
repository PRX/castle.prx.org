defmodule Castle.Repo.Migrations.LongerImageUrls do
  use Ecto.Migration

  def up do
    alter table(:podcasts) do
      modify(:image_url, :text)
    end

    alter table(:episodes) do
      modify(:image_url, :text)
    end
  end

  def down do
    alter table(:podcasts) do
      modify(:image_url, :string)
    end

    alter table(:episodes) do
      modify(:image_url, :string)
    end
  end
end
