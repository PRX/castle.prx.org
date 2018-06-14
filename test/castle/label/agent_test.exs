defmodule Castle.CastleLabelAgentTest do
  use Castle.ConnCase, async: true

  import Castle.Label.Agent

  test "gets agent names" do
    assert find(3) == "Alexa"
  end

  test "gets agent types" do
    assert find(36) == "Mobile App"
  end

  test "gets agent os" do
    assert find(43) == "iOS"
  end

  test "gets unknowns" do
    assert find(0) == "Unknown"
    assert find(123456) == "Unknown"
    assert find(9999999) == "Unknown"
  end

end
