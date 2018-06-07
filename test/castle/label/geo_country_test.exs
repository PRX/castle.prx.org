defmodule Castle.CastleLabelGeoCountryTest do
  use Castle.ConnCase, async: true

  import Castle.Label.GeoCountry

  test "gets country names" do
    assert geo_country("US") == "United States"
    assert geo_country("CA") == "Canada"
    assert geo_country("GB") == "United Kingdom"
  end

  test "gets unknowns" do
    assert geo_country("USA") == "Unknown"
    assert geo_country("") == "Unknown"
    assert geo_country("whatev") == "Unknown"
  end

end
