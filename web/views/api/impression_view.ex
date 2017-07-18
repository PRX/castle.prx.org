defmodule Castle.API.ImpressionView do
  use Castle.Web, :view

  import Castle.API.Helpers

  def render("podcast.json", %{id: id} = data) do
    %{id: id} |> meta_json(data) |> counts_json(data)
  end

  def render("podcast-group.json", %{id: id} = data) do
    %{id: id} |> meta_json(data) |> groups_json(data)
  end

  def render("episode.json", %{guid: guid} = data) do
    %{guid: guid} |> meta_json(data) |> counts_json(data)
  end

  def render("podcast-episode.json", %{guid: guid} = data) do
    %{guid: guid} |> meta_json(data) |> groups_json(data)
  end
end
