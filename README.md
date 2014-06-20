twemproxy image
===============

Implements a proxy in front of redis cluster. It reads the servers from [etcd](https://github.com/coreos/etcd). When you start your redis containers, put their connection information into `etcd` in the `/services/redis/<instance>`:

    etcdctl set /services/redis/01 10.10.100.11:6001
    etcdctl set /services/redis/02 10.10.100.12:6002

The twemproxy container will use [confd](https://github.com/kelseyhightower/confd) to watch the `/services/redis` path.

The twemproxy information will be published to `etcd` and can be retrieved like this:

    etcdctl get /services/twemproxy/listen

which will return something like:

    10.10.100.1:6000