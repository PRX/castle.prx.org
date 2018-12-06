defmodule Mailer.Emails do
  import Bamboo.Email

  def weekly_podcast_snapshot(podcast_id) do
    IO.puts "looking up podcast_id #{podcast_id}"

    new_email(
      to: "foo@example.com",
      from: "me@example.com",
      subject: "Weekly Podcast Report",
      html_body: "<strong>#{podcast_id}</strong>",
      text_body: "welcome"
    )
  end
end

