# Castle.prx.org

## Description

[Phoenix app](http://www.phoenixframework.org) providing an API to PRX metrics in BigQuery.

This project follows the [standards for PRX services](https://github.com/PRX/meta.prx.org/wiki/Project-Standards#services).

## Installation

### Local

To get started, make sure you have completed the [Phoenix install guide](http://www.phoenixframework.org/docs/installation).  Then:

```
# Get the code
git clone git@github.com:PRX/castle.prx.org.git

# Install dependencies
mix deps.get

# Configure your environment (you'll need a bigquery table and service account)
cp env-example .env
vi .env
```

### Docker

Currently on OSX, [Dinghy](https://github.com/codekitchen/dinghy) is probably
the best way to set up your dev environment.  Using VirtualBox is recommended.
Also be sure to install `docker-compose` along with the toolbox.

This project is setup primarily to build a `MIX_ENV=prod` docker image. To avoid
recompiling dependencies every time you run a non-prod docker-compose command,
mount some local directories to mask the build/deps directories in the image.

```
docker-compose build

# mount dev dependencies locally
mkdir _build_docker_compose deps_docker_compose
docker-compose run castle compile

# now you can run a local server
docker-compose up
open http://castle.prx.docker

# or run the tests
docker-compose run castle test
docker-compose run castle test --include external

# or run a single test
docker-compose run castle test test/controllers/api/root_controller_test.exs
```

## Dependencies

BigQuery, Redis, and Postgres.  But if you use docker-compose, you'll only need
to configure BigQuery.

## Usage

```
# Start the phoenix server
mix phx.server

# Or run interactively
iex -S mix phx.server

# Or just get a console
iex -S mix
```

## Tasks

Background worker tasks are configured to run on a cron, in `config/prod.exs`.
By default, these are commented out in `dev.exs`, so you'll need to run them
manually or uncomment that line.  Generally, these tasks run with a `--lock`
flag, which uses a redis lock to prevent multiple prod instances from doing the
same work at the same time.

### Feeder Sync

Sync all podcasts/episodes from `FEEDER_HOST` into your local Postgres database.
By default, will only go through a few pages of results at a time, before
returning.  Use `--all` to process all pages (which might take a long time for
all episodes in Feeder).  Similarly, the `--force` flag will sync all
podcasts/episodes since the beginning of time, and can take a long time.

```
mix feeder.sync [--lock,--all,--force]
```

### Downloads Rollup

This task queries BigQuery for hourly downloads on a single day, and inserts
that day of data into Postgres.  It also updates the `rollup_logs` to keep track
of which days have already been rolled up.

By default, this task will find 5 incomplete days (not present in `rollup_logs`)
and process those.  But you can change that number with the `--count 99` flag.  
Or explicitly rollup a certain day with `--date 20180425`.

Since the rollup operation is idempotent, you can run it on the current day
repeatedly.  But a record will only be added to the `rollup_logs` table 15
minutes after midnight, to make sure BigQuery is completely accurate before
marking the day as "complete".

```
mix castle.rollup.downloads [--lock,--date [YYYYMMDD],--count [INT]]
```

### Totals Rollup

*DEPRECATED* These "all time total" rollups are deprecated, and will soon be
replaced by the Postgres rollups.

```
mix castle.rollup.totals [--lock]
```

## Testing

```
# Run all the tests
mix test

# Run a specific test
mix test test/big_query/base/http_test.exs

# Include external dependency tests (requires a valid .env)
mix test --include external
```

## Scripts

The `/scripts/` directory contains some useful utilities for load/reloading
3rd party data (Geolite, User-Agents, etc).  These are not intended to be run
often, so buyer beware.  You will need to install some global ruby gems to get
the scripts to work, but that's all manual at this point.

You'll also need to [set up a Google API key](https://support.google.com/googleapi/answer/6158862).
Create a Service Account key with write access to the project/tables you want to
alter, and save it to `/scripts/.credentials.json`.

## License

[AGPL License](https://www.gnu.org/licenses/agpl-3.0.html)

## Contributing

Completing a Contributor License Agreement (CLA) is required for PRs to be accepted.
