defmodule Castle.WebPagingTest do
  use Castle.ConnCase, async: true

  import CastleWeb.Paging

  test "parses paging parameters" do
    assert parse_paging(%{}) == {1, 10}
    assert parse_paging(%{"page" => 2}) == {2, 10}
    assert parse_paging(%{"per" => 3}) == {1, 3}
    assert parse_paging(%{"page" => 2, "per" => 3}) == {2, 3}
    assert parse_paging(%{"page" => "2", "per" => "3"}) == {2, 3}
    assert parse_paging(%{"page" => "-2", "per" => "0"}) == {1, 10}
  end

  test "creates default per links" do
    links = paging_links("/api/v1/foobar", %{page: 2, per: 10, total: 99})
    assert links.prev.href == "/api/v1/foobar"
    assert links.next.href == "/api/v1/foobar?page=3"
    assert links.first.href == "/api/v1/foobar"
    assert links.last.href == "/api/v1/foobar?page=10"
  end

  test "creates custom per links" do
    links = paging_links("/api/v1/foobar", %{page: 2, per: 3, total: 15})
    assert links.prev.href == "/api/v1/foobar?per=3"
    assert links.next.href == "/api/v1/foobar?page=3&per=3"
    assert links.first.href == "/api/v1/foobar?per=3"
    assert links.last.href == "/api/v1/foobar?page=5&per=3"
  end

  test "removes prev on the first page" do
    links = paging_links("/api/v1/foobar", %{page: 1, per: 10, total: 22})
    assert Map.has_key?(links, :prev) == false
    assert links.next.href == "/api/v1/foobar?page=2"
    assert links.first.href == "/api/v1/foobar"
    assert links.last.href == "/api/v1/foobar?page=3"
  end

  test "removes next on the last page" do
    links = paging_links("/api/v1/foobar", %{page: 3, per: 10, total: 22})
    assert links.prev.href == "/api/v1/foobar?page=2"
    assert Map.has_key?(links, :next) == false
    assert links.first.href == "/api/v1/foobar"
    assert links.last.href == "/api/v1/foobar?page=3"
  end

  test "includes search params in links" do
    links = paging_links("/api/v1/foobar", %{page: 3, per: 10, total: 22, search: "foo"})
    assert links.prev.href == "/api/v1/foobar?page=2&search=foo"
    assert links.first.href == "/api/v1/foobar?search=foo"
    assert links.last.href == "/api/v1/foobar?page=3&search=foo"
    # first page
    links = paging_links("/api/v1/foobar", %{page: 2, per: 10, total: 22, search: "foo bar"})
    assert links.prev.href == "/api/v1/foobar?search=foo%20bar"
  end
end
