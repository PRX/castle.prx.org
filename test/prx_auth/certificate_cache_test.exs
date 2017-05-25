defmodule PrxAuth.CertificateCacheTest do
  use ExUnit.Case, async: false

  import PrxAuth.Certificate.Cache

  setup do
    cache_clear()
    on_exit fn -> cache_clear() end
    []
  end

  test "sets and gets cache items" do
    assert cache_get("foobar") == {:not_found}
    assert cache_set("some-data", "foobar", 123) == "some-data"
    assert cache_get("foobar") == {:found, 123, "some-data"}
    assert cache_get("foobar") == {:found, 123, "some-data"}
  end

  test "clears cache items" do
    assert cache_set("some-data", "foobar", 123) == "some-data"
    assert cache_get("foobar") == {:found, 123, "some-data"}
    assert cache_clear() == true
    assert cache_get("foobar") == {:not_found}
  end
end
