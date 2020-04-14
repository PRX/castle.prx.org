defmodule Castle.FeederHelpers do
  defmacro __using__(_opts) do
    quote do
      @feeder PrxAccess.Remote.host_to_url(Env.get(:feeder_host))
      @feeder_params "per=100&since=1970-01-01"
      @feeder_podcasts "#{@feeder}/api/v1/authorization/podcasts"
      @feeder_episodes "#{@feeder}/api/v1/authorization/episodes"
      @feeder_all_podcasts "#{@feeder_podcasts}?#{@feeder_params}"
      @feeder_all_episodes "#{@feeder_episodes}?#{@feeder_params}"

      setup do
        Memoize.invalidate({Feeder.Api, :root, []})
        Memoize.Cache.get_or_run({Feeder.Api, :root, []}, fn -> {:ok, feeder_root()} end)
        []
      end

      defp feeder_root do
        %PrxAccess.Resource{
          attributes: %{"userId" => "1234"},
          _links: feeder_root_links(),
          _embedded: %{},
          _url: "#{@feeder}/api/v1/authorization",
          _status: 200
        }
      end

      defp feeder_root_links do
        %{
          "prx:episodes" => %PrxAccess.Resource.Link{
            href: "/api/v1/authorization/episodes{?page,per,zoom,since}"
          },
          "prx:podcasts" => %PrxAccess.Resource.Link{
            href: "/api/v1/authorization/podcasts{?page,per,zoom,since}"
          }
        }
      end
    end
  end
end
