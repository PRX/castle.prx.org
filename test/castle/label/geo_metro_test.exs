defmodule Castle.CastleLabelGeoMetroTest do
  use Castle.ConnCase, async: true

  import Castle.Label.GeoMetro

  test "gets metro/dma code names" do
    assert find(512) == "Baltimore"
    assert find(751) == "Denver"
    assert find(676) == "Duluth-Superior"
  end

  test "gets unknowns" do
    assert find(0) == "Unknown"
    assert find(1) == "Unknown"
    assert find(99999) == "Unknown"
  end

end
