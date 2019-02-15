FROM alpine:latest
LABEL maintainer="Jérémy Derussé <jeremy@derusse.com>"

RUN apk --no-cache add \
    dnsmasq \
    openssl

ENV DOCKER_GEN_VERSION 0.7.4
ENV DOCKER_HOST unix:///var/run/docker.sock

RUN wget -qO- https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin
COPY docker-files/. /

VOLUME /var/run
EXPOSE 53/udp
ENV GATEWAY=172.17.42.1 \
    RESOLV_PATH=

ENTRYPOINT ["entrypoint"]
