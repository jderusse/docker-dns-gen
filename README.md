# Docker DNS-gen

dns-gen sets up a container running Dnsmasq and [docker-gen].
docker-gen generates a configuration for Dnsmasq and reloads it when containers are
started and stopped.

By default it will provide thoses domain:
- `container_name.docker`
- `container_name.network_name.docker`
- `docker-composer_service.docker-composer_project.docker`
- `docker-composer_service.docker-composer_project.network_name.docker`

**easy install:**

    sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/jderusse/docker-dns-gen/master/bin/install)"

## How it works

The container `dns-gen` expose a standard dnsmasq service. It returns ip of
known container and fallback to host's resolv.conf for other domains.

## Requirement

In order to ease the configuration of your host. We recommand to install
`resolvconf`

    apt install resolvconf

The container have to listen on port `53` on `docker0` interface. You should
assert that nothing else is listening to that port.

    sudo netstat -ntlp --udp|grep ":53 "

If some service are listening to the same port, you should changes your
setting to exclude the `docker0` interface.
For instance, in dnsmasq use :

    except-interface=docker0

## Q/A

**Why mounting the entier host in the container (`-v /:/host`)**

The dnsmasq embeded inside the container is configured to fallback to the
default `resolv.conf`. But, given the host is configured to use the container
to resolve DNS, and to avoid infinite loop, the container uses the hosts's
`/etc/resolv.conf` without it own IP.

Mounting the `-v /etc/resolv.conf:/etc/resolv.conf` file is not possible as
this file is often overriden by the host (changing network, connecting to
wifi, connecting to a VPN) and docker wouldn't update the mounted file. And,
in most of the cases, this file is a symlink to another location, and the the
target should be accessible by the container too.

For instances, when using resolvconf on Debian 9:

    /etc/resolv.conf -> /etc/resolvconf/run/resolv.conf
    /etc/resolvconf/run -> /run/resolvconf

**Why not using the container's `/etc/resolv.conf` file?**

First of all, because the user could have configured the `/etc/docker/daemon.json`
to use a specific `name server` inside the container, whereas we are trying to
configure the host's DNS resolution.

Moreover, from my tests, the file is not updated when the host changes it `name
servers`.

**Why using the host network**

Some distributions (like ubuntu) use a local dnsmasq instance to resolv DNS
This instance, runing on the host local network, should be accessible by the
container. Using the `host` network is the easiest way to be as close as
possible to the host.

## Previous version of docker-gen

If you already install and configured a previous version of dns-gen you should
uninstall it.

- uninstall dnsmasq
- remove previous container `docker rm -fv dns-gen`
- remove custom configuration in `/etc/docker/daemon.json`
- remove /etc/NetworkManager/dnsmasq.d/01_docker
- restart the service NetworkManager (and in some case the machine)

## Manual Install

Just run the `all in one` script `./bin/install`

If you want to deep inside, here are the manuall steps to permform the same

First, you have to know the IP of your `docker0` interface. It may be
`172.17.42.1` but it could be something else. To known your IP, run the
following command:

    GATEWAY=$(ip -4 addr show docker0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo ${GATEWAY}

Now, you can start the `dns-gen` container:

    docker run -d --name dns-gen \
      --restart always \
      --net host \
      -e GATEWAY=$GATEWAY \
      --log-opt "max-size=10m" \
      --volume /:/host \
      --volume /var/run/docker.sock:/var/run/docker.sock \
      jderusse/dns-gen:2

You can test the container

    docker run --name test nginx:alpine
    dig test.docker @${GATEWAY}

Once OK, you can finally update your local resolver

    echo "nameserver ${GATEWAY}" | sudo tee --append /etc/resolvconf/resolv.conf.d/head
    resolvconf -u

**beware**! When your host will restart, it may change the IP address of
the `docker0` interface. Mays may have to run the command `bin/install` to fix
your configuration.

Or you can force docker to always use the same IP by editing the
`/etc/docker/daemon.json` file and adding:

    {
      "bip": "172.17.42.1/24"
    }

**One more thing** When you start your host, the docker service is not fully
loaded.
Until this daemon is loaded, the dns container will not be automatically started
and you will notice bad performance when your host will try to resolve DNS.
The service is not fully loaded, because it uses a feature of systemd called
[socket activation]: The first access to the docker socket will trigger the
start of the true service.
To skip this feature, you simply have to activate the docker service.

    sudo update-rc.d docker enable

## Troubleshooting

To see the list of register DNS, dump the content of the generated
`dnsmasq.conf`

    docker exec dns-gen cat /etc/dnsmasq.conf

On restart, if you loose the dns resolution, check the `NetworkManager` service status.

    service NetworkManager status

Check the syntax of the `/etc/resolc.conf` file which should contain at the
begging the IP of the `docker0` interface:

    nameserver 172.17.42.1

Check the containers logs

    docker logs --tail 100 -f dns-gen

  [docker-gen]: https://github.com/jwilder/docker-gen
  [socket activation]: http://0pointer.de/blog/projects/socket-activation.html
  [ansible playbook]: https://gist.github.com/jpic/7bfbe20cf759986b7c7c7851c2d63762
