#!/bin/sh

setkey () {
  true
}
# Run docker run with -e ETCD_HOST=<ip>:<port>
if [ -n "${ETCD_HOST:+x}" ]; then
  mv /etc/supervisor/supervisord.conf /tmp/supervisord.conf
  sed -e "/confd -node/s/127.0.0.1:4001/${ETCD_HOST}/" -e 's/autostart=false/autostart=true/' /tmp/supervisord.conf > /etc/supervisor/supervisord.conf
  setkey () {
    curl -X PUT -d value="$2" -L "http://${ETCD_HOST}/v2/keys/$1"
  }
  curl -L "http://${ETCD_HOST}/v2/keys/services/twemproxy" -XPUT -d dir=true
  curl -L "http://${ETCD_HOST}/v2/keys/services/redis" -XPUT -d dir=true
fi
# Run docker run with -e CONSUL_HOST=<ip>:<port>
if [ -n "${CONSUL_HOST}" ]; then
  mv /etc/supervisor/supervisord.conf /tmp/supervisord.conf
  sed -e "s/confd -node=\"http://127.0.0.1:4001\"/-consul -consul-addr ${CONSUL_HOST}/" -e 's/autostart=false/autostart=true/' /tmp/supervisord.conf > /etc/supervisor/supervisord.conf
  setkey () {
    curl -X PUT -d "$2" "http://${CONSUL_HOST}:${CONSUL_HTTP_PORT:-8500}/v1/kv/$1"
  }
fi

# Remember the port this twemproxy will be using
setkey services/twemproxy/port "${PORT:-6000}"

# Are there any linked containers?
if [ -n "$(env | cut -d= -f1 | grep -e _PORT_${REDIS_PORT:-6379}_TCP_ADDR)" ]; then
  cat <<EOF > /twemproxy.yaml
situ:
  listen: 0.0.0.0:${PORT:-6000}
  hash: fnv1a_64
  hash_tag: "P:"
  distribution: ketama
  auto_eject_hosts: false
  timeout: 1000
  redis: true
  servers:
EOF
  for var in $(env | cut -d= -f1 | grep -e "_PORT_${REDIS_PORT:-6379}_TCP_ADDR"); do
    addr=$(eval echo \$${var})
    port=${REDIS_PORT:-6379}
    echo "  - ${addr}:${port}:1" >> /twemproxy.yaml
    key=$(echo $var | sed -e 's/_PORT.*$//')
    setkey "services/redis/${key}" "${addr}:${port}"
  done
fi

# for debugging
cat /etc/supervisor/supervisord.conf

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
