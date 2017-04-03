defmodule BigQuery.Programs do
  import BigQuery.Base.Query

  def list(now \\ Timex.now) do
    params = %{
      past1:  Timex.shift(now, hours: -1),
      past12: Timex.shift(now, hours: -12),
      past24: Timex.shift(now, hours: -24),
      past48: Timex.shift(now, hours: -48),
      pstart: Timex.beginning_of_day(Timex.shift(now, hours: -48)),
    }

    """
    SELECT program,
      COUNTIF(timestamp > @past1) as past1,
      COUNTIF(timestamp > @past12) as past12,
      COUNTIF(timestamp > @past24) as past24,
      COUNTIF(timestamp > @past48) as past48
    FROM #{Env.get(:bq_impressions_table)}
    WHERE _PARTITIONTIME >= @pstart
      AND is_duplicate = false
    GROUP BY program
    ORDER BY program ASC
    """
    |> query(params)
  end
end
