defmodule Castle.Rollup do

  alias Castle.Rollup.Data, as: Data

  defdelegate podcasts(), to: Data.Totals, as: :podcasts
  defdelegate episodes(), to: Data.Totals, as: :episodes

  defdelegate podcast_total(id), to: Data.Totals, as: :podcast
  defdelegate episode_total(guid), to: Data.Totals, as: :episode

  defdelegate podcast_trends(id), to: Data.Trends, as: :podcast
  defdelegate episode_trends(guid), to: Data.Trends, as: :episode

end
