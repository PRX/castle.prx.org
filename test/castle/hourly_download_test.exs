defmodule Castle.HourlyDownloadTest do
  use Castle.DataCase
  use Castle.TimeHelpers

  import Castle.HourlyDownload

  @id 1234
  @guid "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"

  setup do
    Enum.map list_partitions(), fn(table_name) ->
      Ecto.Adapters.SQL.query!("DROP TABLE #{table_name}")
    end
    []
  end

  test "upserts data to new partitions" do
    assert list_partitions() == []
    assert do_upsert_all("2018-04-24T13:00:00", 111) == 1
    assert list_partitions() == ["hourly_downloads_201804"]
    assert count_partition("201804") == 111
  end

  test "upserts into existing partitions" do
    assert list_partitions() == []
    assert do_upsert_all("2018-04-24T13:00:00", 111) == 1
    assert list_partitions() == ["hourly_downloads_201804"]
    assert count_partition("201804") == 111

    assert do_upsert_all([{"2018-04-24T13:00:00", 222}, {"2018-04-24T12:00:00", 333}]) == 2
    assert list_partitions() == ["hourly_downloads_201804"]
    assert count_partition("201804") == 555
  end

  defp do_upsert_all(dtim, count), do: do_upsert_all([{dtim, count}])
  defp do_upsert_all(rows) when is_list(rows) do
    rows
      |> Enum.map(fn({dtim, count}) -> %{podcast_id: @id, episode_id: @guid, dtim: get_dtim(dtim), count: count} end)
      |> upsert_all()
  end

  defp count_partition(month) do
    query = "select sum(count) from hourly_downloads_#{month}"
    result = Ecto.Adapters.SQL.query!(Castle.Repo, query, [])
    hd(hd(result.rows))
  end

  defp list_partitions do
    query = "select tablename from pg_tables where tablename like 'hourly_downloads\_______'"
    result = Ecto.Adapters.SQL.query!(Castle.Repo, query, [])
    List.flatten(result.rows)
  end

end
