docker-twemproxy
================

Docker image of [twemproxy](https://github.com/twitter/twemproxy) proxy server in front of [redis](http://redis.io/) instances. 

## Overview

If available, the container will poll the redis server information from [etcd](https://github.com/coreos/etcd) or [consul](https://consul.io).

If `ETCD_HOST` or `CONSUL_HOST` are present, the twemproxy container will use [confd](https://github.com/kelseyhightower/confd) to watch the `/services/redis` path. It exposes port 6000, so map that when you do `docker run`.

If you pass a different `PORT` environment variable than 6000, that will be used to populate the `/services/twemproxy/port` path in `etcd` or `consul`, and twemproxy will listen on that port.

When you start your redis containers, put their connection information into `etcd` in the `/services/redis/<instance>`:

    etcdctl set /services/redis/01 10.10.100.11:6001
    etcdctl set /services/redis/02 10.10.100.12:6002

You also need to set the port that you want twemproxy to run on:

    etcdctl set /services/twemproxy/port 6000

Finally, define the `etcd` peer `confd` should use as an [environment variable](https://docs.docker.com/reference/run/#env-environment-variables) using `-e ETCD_HOST=<host>:<port>` when you do the `docker run` to start the container.

If you are running a coreos fleet for docker, you should be able to use the etcd on the docker0 interface on each host by specifying:

    ETCD_HOST=172.17.42.1

If you spin up a cluster of [docker-consul](https://github.com/progrium/docker-consul), the `CONSUL_HTTP_PORT` (default 8500) will be used to detect a consul server:

    CONSUL_PORT_8500_TCP_ADDR=10.10.100.10

This will automatically set the `CONSUL_HOST` at the IP address pointed to above, allowing for an automatic consul linkage discovery.

Neither etcd nor consul is required for this docker image to function.

If there are any environment variables for [docker linked containers](https://docs.docker.com/userguide/dockerlinks/) on the `REDIS_PORT` (default 6379). You can set this simulate this linkage manually by setting the environment variables:

    REDIS1_PORT_6379_TCP_ADDR=10.10.100.11
    REDIS2_PORT_6379_TCP_ADDR=10.10.100.12

If you redefine the `REDIS_PORT` environment variable, be sure to update the port 6379 references in the above variables as well for proper linked container detection.

On startup, a twemproxy yaml config file will be created pointing to them, and etcd or consul will be automatically populated as well. This means you can use environment variables and avoid having to use etcdctl manually to register new redis servers if you wish.

## Usage

You may want to customize the twemproxy configuration in `confd/templates/twemproxy.tmpl` - particularly the `hash_tag` option.

    # start some redis containers
    docker run --name=redis-A --rm -p 6101:6379 dockerfile/redis
    docker run --name=redis-B --rm -p 6102:6379 dockerfile/redis
    # publish the redis host:ip information into etcd
    etcdctl set /services/redis/A 127.0.0.1:6101
    etcdctl set /services/redis/B 127.0.0.1:6102
    # define the desired twemproxy and stats port
    TWEMPROXY_PORT=6100
    TWEMPROXY_STATS_PORT=6100
    # set the twemproxy port in etcd
    etcdctl set /services/twemproxy/port ${TWEMPROXY_PORT}
    # use the port you set above when you start the container
    docker run --name=twemproxy --rm -p ${TWEMPROXY_PORT}:6000 -p ${TWEMPROXY_STATS_PORT}:6001 -e ETCD_HOST=127.0.0.1:4001 jgoodall/twemproxy
    # publish the twemproxy host info if desired
    etcdctl set /services/twemproxy/host 127.0.0.1
    # connect using a redis client
    redis-cli -h `etcdctl get /services/twemproxy/host` -p `etcdctl get /services/twemproxy/port`
    # get stats on cluster (use `docker ps` to get `<ip>`)
    curl <ip>:$TWEMPROXY_STATS_PORT
