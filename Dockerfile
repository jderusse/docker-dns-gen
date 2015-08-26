FROM debian:latest
MAINTAINER Jérémy Derussé "jeremy@derusse.com"

RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    dnsmasq \
    supervisor \

 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

ENV DOCKER_GEN_VERSION 0.4.0

RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    wget \

 && wget --no-check-certificate -qO- https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz | tar xvz -C /usr/local/bin \

 && apt-get purge -y wget \

 && apt-get clean \
 && rm -r /var/lib/apt/lists/*


ENV DOCKER_HOST unix:///var/run/docker.sock

ADD config/dnsmasq.tmpl /etc/dnsmasq.tmpl
ADD config/supervisord.conf /etc/supervisor/conf.d/docker-gen.conf

EXPOSE 53/udp

CMD ["/usr/bin/supervisord", "-n"]