defmodule Insights.WeeklySnapshotTest do

  use ExUnit.Case

  use Castle.DataCase
  use Castle.TimeHelpers

  @id1 UUID.uuid4()
  @id2 UUID.uuid4()
  @id3 UUID.uuid4()

  describe "Insights.WeeklySnapshot.new/1" do
    setup :create_podcasts

    test "new takes in a list of podcast ids" do
      assert Insights.WeeklySnapshot.new([1, 2, 3])
    end

    test "it returns a list of podcasts" do
      snap = Insights.WeeklySnapshot.new([1, 2, 3])
      {:ok, podcasts} = Map.fetch(snap, :podcasts)
      assert length(podcasts) == 3
    end

    test "it returns a list of episodes" do
      not_quite_a_week = Timex.now |> Timex.shift(days: -7, seconds: 1)
      bit_more_than_a_week = Timex.now |> Timex.shift(days: -7, seconds: -1)
      id4 = UUID.uuid4()
      id5 = UUID.uuid4()


      insert!(%Castle.Episode{id: id4, podcast_id: 1, created_at: not_quite_a_week })
      insert!(%Castle.Episode{id: id5, podcast_id: 1, created_at: bit_more_than_a_week })

      snap = Insights.WeeklySnapshot.new([1])

      {:ok, new_episodes} = Map.fetch(snap, :new_episodes)
      assert length(new_episodes) == 1
      assert new_episodes |> Enum.map(fn(e)-> e.id end) == [id4]
    end
  end

  defp create_podcasts(_) do
    insert!(%Castle.Podcast{id: 1, account_id: 123})
    insert!(%Castle.Podcast{id: 2, account_id: 456})
    insert!(%Castle.Podcast{id: 3, account_id: 456})

    insert!(%Castle.Episode{id: @id1, podcast_id: 1})
    insert!(%Castle.Episode{id: @id2, podcast_id: 2})
    insert!(%Castle.Episode{id: @id3, podcast_id: 1})
    {:ok, [podcast_ids: [1, 2, 3]]}
  end
end
