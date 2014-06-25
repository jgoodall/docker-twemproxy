docker-twemproxy
================

Docker image of [twemproxy](https://github.com/twitter/twemproxy) proxy server in front of [redis](http://redis.io/) instances. 

## Overview

The container reads the redis server information from [etcd](https://github.com/coreos/etcd). The twemproxy container will use [confd](https://github.com/kelseyhightower/confd) to watch the `/services/redis` path. It exposes port 6000, so map that when you do `docker run`.

When you start your redis containers, put their connection information into `etcd` in the `/services/redis/<instance>`:

    etcdctl set /services/redis/01 10.10.100.11:6001
    etcdctl set /services/redis/02 10.10.100.12:6002

You also need to set the port that you want twemproxy to run on:

    etcdctl set /services/twemproxy/port 6000

Finally, define the `etcd` peer `confd` should use as an [environment variable](https://docs.docker.com/reference/run/#env-environment-variables) using `-e ETCD_HOST=<host>:<port>` when you do the `docker run` to start the container.

## Usage

    # start some redis containers
    docker run --name=redis-A --rm -p 6101:6379 dockerfile/redis
    docker run --name=redis-B --rm -p 6102:6379 dockerfile/redis
    # publish the redis host:ip information into etcd
    etcdctl set /services/redis/A 127.0.0.1:6101
    etcdctl set /services/redis/B 127.0.0.1:6102
    # define the desired twemproxy port
    TWEMPROXY_PORT=6100
    # set the twemproxy port in etcd
    etcdctl set /services/twemproxy/port ${TWEMPROXY_PORT}
    # use the port you set above when you start the container
    docker run --name=twemproxy --rm -p ${TWEMPROXY_PORT}:6000 -e ETCD_HOST=127.0.0.1:4001 jgoodall/twemproxy
    # publish the twemproxy host info if desired
    etcdctl set /services/twemproxy/host 127.0.0.1
    # connect using a redis client
    redis-cli -h `etcdctl get /services/twemproxy/host` -p `etcdctl get /services/twemproxy/port`
