defmodule BigQuery.Programs do
  import BigQuery.Base.Query

  def list(now \\ Timex.now) do
    BigQuery.Base.HTTP.get_token()
    [
      {"downloads", Env.get(:bq_downloads_table)},
      {"impressions", Env.get(:bq_impressions_table)}
    ]
    |> Enum.map(&Task.async(fn -> query_many(&1, now) end))
    |> Enum.map(&Task.await/1)
    |> combine_output
  end

  def show(program, now \\ Timex.now) do
    BigQuery.Base.HTTP.get_token()
    [
      {"downloads", Env.get(:bq_downloads_table)},
      {"impressions", Env.get(:bq_impressions_table)}
    ]
    |> Enum.map(&Task.async(fn -> query_one(&1, program, now) end))
    |> Enum.map(&Task.await/1)
    |> Enum.reduce(%{}, &Map.merge(&2, &1))
  end

  defp query_many({prefix, table}, now) do
    params = build_params(now)
    """
    SELECT program, #{counts(prefix)}
    FROM #{table}
    WHERE _PARTITIONTIME >= @pstart
      AND is_duplicate = false
    GROUP BY program
    ORDER BY program ASC
    """
    |> query(params)
  end

  defp query_one({prefix, table}, id, now) do
    params = build_params(now) |> Map.put(:program, id)
    """
    SELECT @program as program, #{counts(prefix)}
    FROM #{table}
    WHERE _PARTITIONTIME >= @pstart
      AND is_duplicate = false
      AND program = @program
    """
    |> query(params)
    |> hd
  end

  defp counts(prefix) do
    """
    COUNTIF(timestamp > @past1) as #{prefix}_past1,
    COUNTIF(timestamp > @past12) as #{prefix}_past12,
    COUNTIF(timestamp > @past24) as #{prefix}_past24,
    COUNTIF(timestamp > @past48) as #{prefix}_past48
    """
  end

  defp build_params(now) do
    %{
      past1:  Timex.shift(now, hours: -1),
      past12: Timex.shift(now, hours: -12),
      past24: Timex.shift(now, hours: -24),
      past48: Timex.shift(now, hours: -48),
      pstart: Timex.beginning_of_day(Timex.shift(now, hours: -48)),
    }
  end

  defp combine_output([downloads, impressions]) do
    keys = Enum.map(downloads, &(&1[:program]))
      |> Enum.concat(Enum.map(impressions, &(&1[:program])))
      |> Enum.uniq
    Enum.map(keys, &Map.merge(find_output(&1, downloads), find_output(&1, impressions)))
  end

  defp find_output(program, data) do
    Enum.find(data, %{}, &(&1[:program] == program))
  end
end
