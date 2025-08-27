defmodule Fixer do
  import Ecto.Changeset
  import Ecto.Query

  def one do
    ep = Castle.Repo.one(from(e in Castle.Episode, where: is_nil(e.guid), limit: 1))

    case Feeder.Api.root() |> PrxAccess.follow("prx:episode", id: ep.id) do
      {:error, %PrxAccess.Error{json: %{"status" => 410}}} ->
        guid = "prx_#{ep.podcast_id}_#{ep.id}"
        ep2 = Ecto.Changeset.change(ep, %{guid: guid}) |> Castle.Repo.update!()
        IO.puts("defaulted #{ep.id} -> #{ep2.guid}")

      {:error, %PrxAccess.Error{json: %{"status" => 404}}} ->
        guid = "prx_#{ep.podcast_id}_#{ep.id}"
        ep2 = Ecto.Changeset.change(ep, %{guid: guid}) |> Castle.Repo.update!()
        IO.puts("default404d #{ep.id} -> #{ep2.guid}")

      {:ok, doc} ->
        ep2 = Castle.Episode.from_feeder(ep, doc)
        IO.puts("fixed #{ep.id} -> #{ep2.guid}")
    end
  end
end

# for i <- 0..1000, do: Fixer.one()
