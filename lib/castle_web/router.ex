defmodule CastleWeb.Router do
  use CastleWeb, :router

  pipeline :api, do: plug :accepts, ["json", "hal"]
  pipeline :logged, do: plug Plug.Logger

  pipeline :authorized, do: plug Castle.Plugs.Auth
  pipeline :authorized_podcast, do: plug Castle.Plugs.AuthPodcast
  pipeline :authorized_episode, do: plug Castle.Plugs.AuthEpisode

  pipeline :hourly_metrics, do: plug Castle.Plugs.Interval, min: "HOUR"
  pipeline :ranked_metrics do
    plug Castle.Plugs.Interval, min: "DAY"
    plug Castle.Plugs.Group
  end
  pipeline :total_metrics do
    plug Castle.Plugs.Interval, min: "DAY", skip_bucket: true
    plug Castle.Plugs.Group
  end
  pipeline :listener_metrics do
    plug Castle.Plugs.Interval
  end

  scope "/", CastleWeb do
    pipe_through :api
    get "/", RedirectController, :index
    get "/api", RedirectController, :index
    get "/api/v1", API.RootController, :index, as: :api_root
  end

  scope "/api/v1", CastleWeb.API, as: :api do
    pipe_through :api
    pipe_through :logged
    pipe_through :authorized

    resources "/podcasts", PodcastController, only: [:index]

    scope "/podcasts" do
      pipe_through :authorized_podcast

      resources "/", PodcastController, only: [:show]
      resources "/:id/episodes", EpisodeController, only: [:index], as: :podcast_episode

      scope "/:id/downloads", as: :podcast do
        pipe_through :hourly_metrics
        resources "/", DownloadController, only: [:index]
      end
      scope "/:id/listeners", as: :podcast do
        pipe_through :listener_metrics
        resources "/", ListenerController, only: [:index]
      end
      scope "/:id/ranks", as: :podcast do
        pipe_through :ranked_metrics
        resources "/", RankController, only: [:index]
      end
      scope "/:id/totals", as: :podcast do
        pipe_through :total_metrics
        resources "/", TotalController, only: [:index]
      end
    end

    resources "/episodes", EpisodeController, only: [:index]

    scope "/episodes" do
      pipe_through :authorized_episode

      resources "/", EpisodeController, only: [:show]

      scope "/:id/downloads", as: :episode do
        pipe_through :hourly_metrics
        resources "/", DownloadController, only: [:index]
      end
      scope "/:id/ranks", as: :episode do
        pipe_through :ranked_metrics
        resources "/", RankController, only: [:index]
      end
      scope "/:id/totals", as: :episode do
        pipe_through :total_metrics
        resources "/", TotalController, only: [:index]
      end
    end

  end

end
