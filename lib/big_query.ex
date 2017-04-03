defmodule BigQuery do

  defdelegate programs(), to: BigQuery.Programs, as: :list
  defdelegate program(id), to: BigQuery.Programs, as: :show

end
