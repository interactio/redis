ARG REDIS_VERSION=7.0

# Because https://hub.docker.com/_/redis is Debian based
FROM debian:11 as build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
	apt install -y git python3 python3-dev build-essential ca-certificates curl wget unzip rsync lcov make

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
	. $HOME/.cargo/env && rustup default nightly && rustup update

RUN . $HOME/.cargo/env && \
	git clone --recursive https://github.com/RedisJSON/RedisJSON.git && \
	cd RedisJSON && \
	./sbin/setup && \
	make build

FROM redis:$REDIS_VERSION

LABEL org.opencontainers.image.vendor="Interactio" \
      org.opencontainers.image.title="redis"

COPY --from=build /RedisJSON/bin/linux-*-release/rejson.so /usr/local/lib

CMD [ "redis-server", "--loadmodule", "/usr/local/lib/rejson.so" ]
