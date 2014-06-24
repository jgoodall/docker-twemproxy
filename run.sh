#!/bin/sh

# Run docker run with -e ETCD_HOST=<ip>:<port>
echo "environment = ETCD_HOST=${ETCD_HOST}" >> /etc/supervisor/supervisord.conf

# for debugging
cat /etc/supervisor/supervisord.conf

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf