# expected values in etcd
#  - `/services/twemproxy/listen` : the host_ip:port the proxy will listen on
#  - `/services/twemproxy/servers/<num>` : enumeration of the redis servers for 01-N servers, in the format of host_ip:port
# example:
# etcdctl set /services/twemproxy/listen 10.10.100.1:6000
# etcdctl set /services/redis/01 10.10.100.11:6001
# etcdctl set /services/redis/02 10.10.100.12:6002

FROM jgoodall/ubuntu-confd

MAINTAINER "John Goodall <jgoodall@ornl.gov>"

ENV DEBIAN_FRONTEND noninteractive

# Install basics
RUN apt-get update
RUN apt-get -qy install libtool make automake

# Install twemproxy
RUN curl -qL https://twemproxy.googlecode.com/files/nutcracker-0.3.0.tar.gz | tar xzf -
RUN cd nutcracker-0.3.0 && ./configure --enable-debug=log && make && mv src/nutcracker /twemproxy
RUN cd / && rm -rf nutcracker-0.3.0

# Set up run script
ADD run.sh /run.sh
RUN chmod 755 /run.sh

# Copy confd files
ADD confd/conf.d/twemproxy.toml /etc/confd/conf.d/twemproxy.toml
ADD confd/templates/twemproxy.tmpl /etc/confd/templates/twemproxy.tmpl

# Copy supervisord files
ADD supervisord.conf /etc/supervisor/supervisord.conf

EXPOSE 6000 6222

CMD ["/run.sh"]