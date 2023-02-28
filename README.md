# Castle.prx.org

## Description

[Phoenix App](http://www.phoenixframework.org) providing an API to PRX metrics in BigQuery.

This project follows the [standards for PRX services](https://github.com/PRX/meta.prx.org/wiki/Project-Standards#services).

## Installation

### Local

To get started, make sure you have completed the [Phoenix install guide](https://hexdocs.pm/phoenix/installation.html#content).  Then:

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

### Authorization

By default, Castle will restrict what podcasts you can see based on the
account-ids granted to you by [ID](https://github.com/PRX/id.prx.org). If you
want to impersonate other accounts, just set `DEV_AUTH=123,456,789` in your
ENV to grant you access to that comma-separated list of account ids. You can
also set `DEV_AUTH=*` to allow access to all accounts.

Note that the `DEV_AUTH` ENV does not work at all in production environments.

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

### BigQuery Sync

Sync all podcasts/episodes from your local Postgres database back to BigQuery.
Currently, this replaces the entire table in BigQuery, but someday we may want
a more progressive sync process.

```
mix bigquery.sync.podcasts [--lock]
mix bigquery.sync.episodes [--lock]
mix bigquery.sync.agentnames [--lock]
mix bigquery.sync.geonames [--lock]
```

### Downloads Rollup

These tasks query BigQuery for `dt_downloads` on a single day, and inserts that
day of data into Postgres.  It also updates the `rollup_logs` to keep  track
track of which days have already been rolled up, and marks them as "complete"
days if that day is in the past.

The only exception to this is the `monthly_downloads` table, which is calculated
from the `hourly_downloads` to provide more efficient access to podcast/episode
"total" downloads, without having to scan every partition of hourly data.

By default, most tasks will find 5 incomplete days (not present in `rollup_logs`)
and process those.  But you can change that number with the `--count 99` flag.  
Or explicitly rollup a certain day with `--date 20180425`.  Rollup operations
are idempotent, you can run them repeatedly for the same day/month.

These are all the rollup tasks available:

```
mix castle.rollup.hourly [--lock,--date [YYYYMMDD],--count [INT]]
mix castle.rollup.monthly [--lock,--date [YYYYMMDD],--count [INT]]
mix castle.rollup.geocountries [--lock,--date [YYYYMMDD],--count [INT]]
mix castle.rollup.geometros [--lock,--date [YYYYMMDD],--count [INT]]
mix castle.rollup.geosubdivs [--lock,--date [YYYYMMDD],--count [INT]]
mix castle.rollup.agents [--lock,--date [YYYYMMDD],--count [INT]]
mix castle.rollup.weekly_uniques [--lock,--date [yyyymmdd],--count [int]]
mix castle.rollup.monthly_uniques [--lock,--date [YYYYMMDD],--count [INT]]
mix castle.rollup.last_week_uniques [--lock,--date [YYYYMMDD],--count [INT]]
mix castle.rollup.last_28_uniques [--lock,--date [YYYYMMDD],--count [INT]]
```

### BigQuery Migrations

Changes to the BigQuery table structures are defined in `priv/migrations/***.exs`. These are
**NOT** run automatically on deploy, and will need to be run locally.

To run or rollback migrations:

1. Change your local `.env` to have a `BQ_PRIVATE_KEY` that can make schema changes.
2. Change your local `.env` to have the `BQ_DATASET` you want to change. **ALWAYS** try out
   your changes in development/staging before production.
3. Run `mix bigquery.migrate` to run a single migration at a time.
   - You'll be prompted many times to double-check you know what you're doing.
   - Watch the output, and double-check the changes it made to your schema.
   - Alternatively, `mix bigquery.rollback` rolls back a single migration.
   - Note that BigQuery will eventually throw `was recently deleted` errors if you keep adding
     and removing the same column names.

To add a new migration, just do something like:

```bash
touch "priv/big_query/migrations/$(date -u +"%Y%m%d%H%M%S")_make_a_change.exs"
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
often, so buyer beware.

You will need to install ruby and some gems to get the scripts to work.
These are managed with `.ruby-version` and `Gemfile`, install them as follows:
```
# install the ruby specified in /scripts/.ruby-version
rbenv install

# install the necessary gems
bundle install
```

You'll also need to [set up a Google API key](https://support.google.com/googleapi/answer/6158862).
Create a Service Account key with write access to the project/tables you want to
alter, and save it to `/scripts/.credentials.json`.

## License

[AGPL License](https://www.gnu.org/licenses/agpl-3.0.html)

## Contributing

Completing a Contributor License Agreement (CLA) is required for PRs to be accepted.

