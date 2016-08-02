FROM ubuntu:16.04

# derived from several excellent base dockerfiles:
# minimesos
# Krijger/docker-cookbooks
MAINTAINER Andreas Streichardt <andreas@arangodb.com>

# supervisor installation && 
# create directory for child images to store configuration in
RUN apt-get update && \
apt-get -y install supervisor iptables curl git sed nginx-extras lua-cjson jq && \
mkdir -p /var/log/supervisor && \
mkdir -p /etc/supervisor/conf.d

RUN mkdir -p /usr/lib/jvm/java-9-openjdk-amd64/conf/management/ && touch /usr/lib/jvm/java-9-openjdk-amd64/conf/management/management.properties
    
RUN echo "deb http://repos.mesosphere.io/ubuntu vivid main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
    apt-get update && \
    apt-get -y install mesos marathon

RUN curl -so /usr/bin/docker https://get.docker.com/builds/Linux/x86_64/docker-1.10.3 && chmod +x /usr/bin/docker

ADD ./container/distribute-slave-resources /distribute-slave-resources
ADD ./container/dcos-cluster.sh /dcos-cluster.sh

ADD ./container/mesos-dns-config.json /etc/mesos-dns-config.json
RUN curl -sLo /usr/bin/mesos-dns https://github.com/mesosphere/mesos-dns/releases/download/v0.5.2/mesos-dns-v0.5.2-linux-amd64
RUN chmod +x /usr/bin/mesos-dns

RUN /etc/init.d/nginx stop
RUN rm -Rf /etc/nginx/conf && git clone https://github.com/dcos/adminrouter /etc/nginx/conf
RUN sed -i.bak -e 's/^resolver.*/resolver 127.0.0.1:53;/g' /etc/nginx/conf/common/http.conf
RUN cp /etc/nginx/mime.types /etc/nginx/conf/mime.types

COPY container/supervisor /etc/supervisor

ENTRYPOINT ["/dcos-cluster.sh"]
