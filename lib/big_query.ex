defmodule BigQuery do

  defdelegate hourly_downloads(), to: BigQuery.Rollup
  defdelegate hourly_downloads(dtim), to: BigQuery.Rollup

end
