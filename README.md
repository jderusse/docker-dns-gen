# Docker DNS-gen

dns-gen sets up a container running Dnsmasq and [docker-gen].
docker-gen generates a configuration for Dnsmasq and reloads it when containers are
started and stopped.

### Usage

First, you have to know the IP of your `docker0` interface. It may be
`172.17.42.1` but it could be something else. To known your IP, run the
following command:

    $ /sbin/ifconfig docker0 | grep "inet addr" | awk '{ print $2}' | cut -d: -f2

Now, you can start the `dns-gen` container:

    $ docker run -d --name dns-gen -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock jderusse/dns-gen

Last thing: Register you new DnsServer in you resolv.conf

    $ echo "nameserver 172.17.42.1" | sudo tee --append /etc/resolvconf/resolv.conf.d/head
    $ sudo resolvconf -u

This is it. You can now start your containers and retrieve their IP:

    $ docker run --name my_app -d nginx
    $ dig my_app.docker
    $ dig sub.my_app.docker

You can customize the DNS name by providing an environment variable, like this:
`DOMAIN_NAME=subdomain.youdomain.com`

    $ docker run -e DOMAIN_NAME=foo.com -d nginx
    $ dig foo.com
    $ dig sub.foo.com
    $ docker run -e DOMAIN_NAME=bar.com,baz.com -d nginx
    $ dig bar.com
    $ dig baz.com

## Start the container automatically after reboot

You can tell docker (version >= 1.2) to automatically start the DNS container
after booting, by passing the option `--restart always` to your `run` command.

    $ docker run -d --name dns-gen --restart always -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock jderusse/dns-gen

**beware**! When your host will restart, it may change the IP address of
the `docker0` interface.
This small change will prevent docker to start your dns-gen container.  Indeed,
remember our container is configured to forward port 53 to the previous
`docker0` interface which may not exist after reboot.  Your container just will
not start, you will have to re-create it. To solve this drawback, force docker
to always use the same IP range by editing the default configuration of the docker
daemon (sometimes located in `/etc/default/docker` but may change regarding
your distribution). You have to restart the docker service to take the changes
into account. Sometimes the interface is not updated, you will have to restart
your host.

    $ vim /etc/default/docker
    DOCKER_OPTS="--bip=172.17.42.1/24"

    $ sudo service docker restart

**One more thing** When you start your host, the docker service is not fully
loaded.
Until this daemon is loaded, the dns container will not be automatically started
and you will notice bad performance when your host will try to resolve DNS.
The service is not fully loaded, because it uses a feature of systemd called
[socket activation]: The first access to the docker socket will trigger the
start of the true service.
To skip this feature, you simply have to activate the docker service.

    $ sudo update-rc.d docker enable

Et voila, now, docker will really start with your host, it will always
use the same range of IP addresses and will always start/restart the container
dns-gen.

### Bonus

You can automatically update the resolv.conf of the container when your host
changes its DNS (ie: network switching) by using the container [dns-sync].

    $ docker run -d --name dns-sync \
        --restart always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /etc:/data/dns/etc \
        -v /run:/data/dns/run \
        jderusse/dns-sync

When coupled with dns-sync, you can force all containers to use this DNS by
updating the docker's default options

    $ vim /etc/default/docker
    DOCKER_OPTS="--bip=172.17.42.1/24 --dns=172.17.42.1"

    $ sudo service docker restart

  [docker-gen]: https://github.com/jwilder/docker-gen
  [socket activation]: http://0pointer.de/blog/projects/socket-activation.html
  [dns-sync]: https://github.com/jderusse/docker-dns-sync
