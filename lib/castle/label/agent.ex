defmodule Castle.Label.Agent do

  @default "Unknown"

  @labels %{
    1 => "HermesPod",
    2 => "Acast",
    3 => "Alexa",
    4 => "AllYouCanBooks",
    5 => "AntennaPod",
    6 => "Breaker",
    7 => "Castaway",
    8 => "CastBox",
    9 => "Castro",
    10 => "Clementine",
    11 => "Downcast",
    12 => "iTunes",
    13 => "NPR One",
    14 => "Overcast",
    15 => "Player FM",
    16 => "Pocket Casts",
    17 => "Podbean",
    18 => "PodcastAddict",
    19 => "The Podcast App",
    20 => "Podkicker",
    21 => "RadioPublic",
    22 => "Sonos",
    23 => "Stitcher",
    24 => "Zune",
    25 => "Podcasts",
    26 => "Internet Explorer",
    27 => "Safari",
    28 => "Firefox",
    29 => "Chrome",
    30 => "Facebook",
    31 => "Twitter",
    32 => "Apple News",
    33 => "BeyondPod",
    34 => "NetCast",
    35 => "Desktop App",
    36 => "Mobile App",
    37 => "Smart Home",
    38 => "Smart TV",
    39 => "Desktop Browser",
    40 => "Mobile Browser",
    41 => "Windows",
    42 => "Android",
    43 => "iOS",
    44 => "Amazon OS",
    45 => "macOS",
    46 => "BlackBerryOS",
    47 => "Windows Phone",
    48 => "ChromeOS",
    49 => "Linux",
    50 => "webOS",
  }

  def agent_name(id) when is_integer(id) do
    @labels[id] || @default
  end

  def agent_type(id) when is_integer(id) do
    @labels[id] || @default
  end

  def agent_os(id) when is_integer(id) do
    @labels[id] || @default
  end

end
