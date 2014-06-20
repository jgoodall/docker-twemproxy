#!/bin/bash
/confd -node="http://${ETCD_HOST}:4001" && sleep 5
exec supervisord -n -c /etc/supervisor/supervisord.conf