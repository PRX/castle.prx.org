defmodule BigQuery do

  defdelegate query(str), to: BigQuery.Query
  defdelegate query(str, params), to: BigQuery.Query

end
