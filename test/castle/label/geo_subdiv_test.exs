defmodule Castle.CastleLabelGeoSubdivTest do
  use Castle.ConnCase, async: true

  import Castle.Label.GeoSubdiv

  test "gets subdivision names" do
    assert find("US-CO") == "Colorado"
    assert find("US-MN") == "Minnesota"
    assert find("GB-SCT") == "Scotland"
  end

  test "gets unknowns" do
    assert find("US") == "Unknown"
    assert find("US-NOPE") == "Unknown"
  end

end
