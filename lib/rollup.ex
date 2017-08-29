defmodule Castle.Rollup do

  alias Castle.Rollup.Data, as: Data

  defdelegate total_podcast_downloads(id), to: Data.Totals, as: :podcast_downloads
  defdelegate total_episode_downloads(guid), to: Data.Totals, as: :episode_downloads

end
