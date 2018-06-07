defmodule Castle.CastleLabelGeoMetroTest do
  use Castle.ConnCase, async: true

  import Castle.Label.GeoMetro

  test "gets metro/dma code names" do
    assert geo_metro(512) == "Baltimore"
    assert geo_metro(751) == "Denver"
    assert geo_metro(676) == "Duluth-Superior"
  end

  test "gets unknowns" do
    assert geo_metro(0) == "Unknown"
    assert geo_metro(1) == "Unknown"
    assert geo_metro(99999) == "Unknown"
  end

end
