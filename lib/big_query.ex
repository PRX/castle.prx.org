defmodule BigQuery do

  defdelegate get_token, to: BigQuery.Auth
  defdelegate query(str), to: BigQuery.Query

end
