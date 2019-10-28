defmodule Castle.LastWeekUniqueTest do
  use Castle.DataCase, async: true

  import Castle.LastWeekUnique

  @id 1234

  test "upserts all" do
    upsert_all [
      %{podcast_id: @id, week: ~D[2018-01-01], count: 10},
      %{podcast_id: @id, week: ~D[2018-02-01], count: 11},
      %{podcast_id: @id, week: ~D[2018-03-01], count: 12}
    ]
    downs = Repo.all(from d in Castle.LastWeekUnique)
    assert length(downs) == 3
    assert Enum.at(downs, 0).count == 10
    assert Enum.at(downs, 1).count == 11
    assert Enum.at(downs, 2).count == 12
  end
end
