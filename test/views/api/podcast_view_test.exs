defmodule Porter.API.PodcastViewTest do
  use Porter.ConnCase, async: true

  import Porter.API.PodcastView

  test "index.json", %{conn: conn} do
    doc = render("index.json", %{conn: conn, programs: test_programs()})
    embedded = doc[:"_embedded"][:"prx:items"]

    assert doc.count == 2
    assert doc.total == 2
    assert length(embedded) == 2
    assert hd(embedded).name == "foo"
    assert hd(embedded).downloads.past1 == 10
  end

  test "show.json", %{conn: conn} do
    doc = render("show.json", %{conn: conn, program: test_program("foo")})
    assert doc.name == "foo"
    assert doc.downloads.past1 == 10
    assert doc.downloads.past12 == 20
    assert doc.downloads.past24 == 30
    assert doc.downloads.past48 == 40
    assert doc.impressions.past1 == 0
    assert doc.impressions.past12 == 0
    assert doc.impressions.past24 == 7
    assert doc.impressions.past48 == 9
  end

  defp test_programs do
    Enum.map(["foo", "bar"], &test_program/1)
  end

  defp test_program(name) do
    %{program: name,
      downloads_past1: 10, downloads_past12: 20, downloads_past24: 30, downloads_past48: 40,
      impressions_past1: nil, impressions_past12: 0, impressions_past24: 7, impressions_past48: 9}
  end
end
