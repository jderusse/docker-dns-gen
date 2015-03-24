# Docker DNS-gen

dns-gen sets up a container running Dnsmasq and [docker-gen][1].
docker-gen generates a configs for Dnsmasq and reloads it when containers are
started and stopped.

### Usage

First you have to know the IP of your `Docker0` interface. It may be
`172.17.42.1` but it could be something else. To known your IP, run the
following command:

    $ /sbin/ifconfig docker0 | grep "inet addr" | awk '{ print $2}' | cut -d: -f2

Now, you can start the `dns-gen` container:

    $ docker run -d --name dns -p 172.17.42.1:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock jderusse/dns-gen

Last things: Register you new DnsServer in you resolv.conf

    $ echo "nameserver 172.17.42.1" | sudo tee --append /etc/resolvconf/resolv.conf.d/head
    $ sudo resolvconf -u

That is. You can now start yours containers and retreive there IP:

    $ docker run -name my_app -d nginx
    $ dig my_app.docker
    $ dig sub.my_app.docker

You can customize the DNS name by providing an env var `DOMAIN_NAME=subdomain.youdomain.com`

    $ docker run -e DOMAIN_NAME=foo.com -d nginx
    $ dig foo.com
    $ dig sub.foo.com
    $ docker run -e DOMAIN_NAME=bar.com,baz.com -d nginx
    $ dig bar.com
    $ dig baz.com


### Bonus

You'll find in this repository a `dns.py` wich simplfy the bootstrap by
starting the dns-gen containers and register the IP in resolv.conf

  [1]: https://github.com/jwilder/docker-gen
