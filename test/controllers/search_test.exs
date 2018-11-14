defmodule Castle.SearchTest do
  use Castle.ConnCase, async: true

  import CastleWeb.Search

  test "parses search query into postgres compatible query" do
    assert prefix_search("test") == "test:*"
    assert prefix_search("test ") == "test"
    assert prefix_search(" test ") == "test"
    assert prefix_search(" test") == "test:*"
    assert prefix_search("  test") == "test:*"
    assert prefix_search("test foo") == "test|foo:*"
    assert prefix_search("test        foo") == "test|foo:*"
    assert prefix_search("test :::") == "test:*"
  end
end
