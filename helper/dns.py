#!/usr/bin/env python

import subprocess
import socket
import fcntl
import struct
import sys
import os

if os.geteuid() != 0:
    os.execvp("sudo", ["sudo"] + sys.argv)


def get_ip_address(ifname):
    ''' retreive IP from given interface name
    '''
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,    # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])

# Warmup docker interface
subprocess.Popen(['docker', 'run', '--rm', 'busybox'], stdout=subprocess.PIPE).communicate()

# Retreive Docker0 IP
docker_ip = get_ip_address('docker0')
if not docker_ip:
    print('\033[31mNo IP found for interface docker\033[0m')
    sys.exit(1)

print('Docker0 IP %s' % docker_ip)

# Restore previous resolv
with open('/etc/resolvconf/resolv.conf.d/head', 'r') as f:
    resolvconf = [x.strip() for x in f if '# docker-dns-gen' not in x and docker_ip not in x]
with open('/etc/resolvconf/resolv.conf.d/head', 'w') as f:
    f.write('\n'.join(resolvconf) + '\n')
subprocess.call(['resolvconf', '-u'])

# Get default DNS
(resolv, _) = subprocess.Popen(['docker', 'run', '--rm', 'busybox', 'cat', '/etc/resolv.conf'], stdout=subprocess.PIPE).communicate()
dns_servers = [x for x in [x[11:].strip() for x in resolv.splitlines() if x.startswith('nameserver ')] if x not in ('127.0.0.1', docker_ip)]
if not len(dns_servers):
    print('\033[31mNo name server found. Dis you use 127.0.0.1?\033[0m')
    sys.exit(1)

# Remove previous dns container
subprocess.Popen(['docker', 'rm', '-f', 'dns-gen'], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

# Start dns container
subprocess.Popen(['docker', 'run', '-td', '--name', 'dns-gen', '-p', '%s:53:53/udp' % docker_ip, '-v', '/var/run/docker.sock:/var/run/docker.sock', 'jderusse/dns-gen'], stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()

# Add container in resolvconf
resolvconf.append('nameserver %s # docker-dns-gen' % docker_ip)
with open('/etc/resolvconf/resolv.conf.d/head', 'w') as f:
    f.write('\n'.join(resolvconf) + '\n')
subprocess.call(['resolvconf', '-u'])
