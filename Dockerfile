FROM elixir:1.13.4-alpine AS builder

WORKDIR /opt/app
ENTRYPOINT [ "./bin/application" ]

RUN apk add --no-cache git
RUN mix local.rebar --force && mix local.hex --force

ADD mix.exs mix.lock ./
RUN MIX_ENV=dev mix do deps.get, deps.compile
RUN grep 'version:' mix.exs | cut -d '"' -f2 > .version

ADD . ./

RUN mkdir -p /opt/built && \
    MIX_ENV=prod SECRET_KEY_BASE=fake mix deps.get && \
    MIX_ENV=prod SECRET_KEY_BASE=fake mix compile && \
    MIX_ENV=prod SECRET_KEY_BASE=fake mix distillery.release && \
    cp _build/prod/rel/castle/releases/$(cat .version)/castle.tar.gz /opt/built && \
    cd /opt/built && \
    tar -xzf castle.tar.gz && \
    rm castle.tar.gz

# NOTE: alpine version here must match the above elixir image
# you can find with "grep VERSION_ID /etc/os-release | cut -d "=" -f2"
FROM alpine:3.17.2 AS built
LABEL maintainer="PRX <sysadmin@prx.org>"
LABEL org.prx.app="yes"
LABEL org.prx.spire.publish.ecr="ELIXIR_APP"
ENV MIX_ENV=prod
ENV USE_BUILT=true
WORKDIR /opt/app
COPY --from=builder /opt/built .
COPY --from=builder /opt/app/bin/* bin/
ENTRYPOINT [ "./bin/application" ]
CMD web
