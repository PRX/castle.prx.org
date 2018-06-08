defmodule Castle.CastleLabelGeoCountryTest do
  use Castle.ConnCase, async: true

  import Castle.Label.GeoCountry

  test "gets country names" do
    assert find("US") == "United States"
    assert find("CA") == "Canada"
    assert find("GB") == "United Kingdom"
  end

  test "gets unknowns" do
    assert find("USA") == "Unknown"
    assert find("") == "Unknown"
    assert find("whatev") == "Unknown"
  end

end
