defmodule Castle.CastleLabelGeoSubdivTest do
  use Castle.ConnCase, async: true

  import Castle.Label.GeoSubdiv

  test "gets subdivision names" do
    assert geo_subdiv("US-CO") == "Colorado"
    assert geo_subdiv("US-MN") == "Minnesota"
    assert geo_subdiv("GB-SCT") == "Scotland"
  end

  test "gets unknowns" do
    assert geo_subdiv("US") == "Unknown"
    assert geo_subdiv("US-NOPE") == "Unknown"
  end

end
