defmodule Mailer.Emails do
  import Bamboo.Email
  use Bamboo.Phoenix, view: Mailer.EmailView

  def weekly_podcast_snapshot(podcast_id, email_address) do
    IO.puts "looking up podcast_id #{podcast_id}"

    render_data = Insights.WeeklySnapshot.new([podcast_id])
    |> Map.merge(%{email_address: email_address})

    new_email()
    |> to("foo@example.com")
    |> from("us@example.com")
    |> subject("Weekly Podcast Report")
    |> put_text_layout({Mailer.LayoutView, "email.text"})
    |> render("weekly_snapshot.text", render_data)
    |> put_html_layout({Mailer.LayoutView, "email.html"})
    |> render("weekly_snapshot.html", render_data)

  end
end

