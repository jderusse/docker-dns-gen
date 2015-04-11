# Docker DNS-gen

dns-gen sets up a container running Dnsmasq and [docker-gen].
docker-gen generates a configs for Dnsmasq and reloads it when containers are
started and stopped.

### Usage

First you have to know the IP of your `docker0` interface. It may be
`172.17.42.1` but it could be something else. To known your IP, run the
following command:

    $ /sbin/ifconfig docker0 | grep "inet addr" | awk '{ print $2}' | cut -d: -f2

Now, you can start the `dns-gen` container:

    $ docker run -d --name dns-gen -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock jderusse/dns-gen

Last things: Register you new DnsServer in you resolv.conf

    $ echo "nameserver 172.17.42.1" | sudo tee --append /etc/resolvconf/resolv.conf.d/head
    $ sudo resolvconf -u

That is. You can now start yours containers and retreive there IP:

    $ docker run --name my_app -d nginx
    $ dig my_app.docker
    $ dig sub.my_app.docker

You can customize the DNS name by providing an env var `DOMAIN_NAME=subdomain.youdomain.com`

    $ docker run -e DOMAIN_NAME=foo.com -d nginx
    $ dig foo.com
    $ dig sub.foo.com
    $ docker run -e DOMAIN_NAME=bar.com,baz.com -d nginx
    $ dig bar.com
    $ dig baz.com

## Start the container automaticly after reboot

You can tel docker (version >= 1.2) to start automaticly the containers after
booting, by passing the option `--restart always` to your `run` command.

    $ docker run -d --name dns-gen --restart always -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock jderusse/dns-gen

**beware**! When your host will restart, it may change the addresse IP of
the `docker0` interface.
This small change will prevent docker to start your dns-gen container.
Indeed, rememeber our container is configurered to forward the port 53 to the
previous `docker0` interface which may not existe after reboot.
Your container just wont start, you'll have to re-create it.
To solve this drawback, force docker to always use the same IP range by
editing the default configuration of docker daemon (sometime located in
`/etc/default/docker` but may change regarding your distribution).
You have to restart the docker service to take the changes it account.
Sometime the interface is not updated, you'll have to restart your host.

    $ vim /etc/default/docker
    DOCKER_OPTS="--bip=172.17.42.1/24"

    $ sudo service docker restart

**One more thing** When you start your host, the docker service is not fully
loaded.
Until this daemon is loaded, the dns container will not be automaticly started
and you'll notice "slowness" when your host will try to resolve DNS.
The service is not fully loaded, because it use a feature of systemd called
[socket activation]: The first access to the docker's socket will trigger the
start of the true service.
To skip this feature, you simply have to activate
the docker service.

    $ sudo update-rc.d docker enable

Et voila, now, docker will really start with your host, it will always
use the same range of IP addresses and will always start/restart the container
dns-gen.

### Bonus

You'll find in this repository a `dns.py` wich simplfy the bootstrap by
starting the dns-gen containers and register the IP in resolv.conf

  [docker-gen]: https://github.com/jwilder/docker-gen
  [socket activation]: http://0pointer.de/blog/projects/socket-activation.html
