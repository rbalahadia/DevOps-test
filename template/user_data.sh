#!/bin/bash
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo service amazon-ssm-agent start
sudo yum install docker -y
sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo service docker start
sudo yum install nginx -y
mkdir /opt/kafka-cluster
cd /opt/kafka-cluster
service nginx start
wget https://downloads.apache.org/kafka/3.4.0/kafka_2.13-3.4.0.tgz
tar -xf kafka_2.13-3.4.0.tgz
rm -rf kafka_2.13-3.4.0.tgz
mkdir dockerfiles configfiles
cd dockerfiles
echo "FROM openjdk:20-slim-buster
WORKDIR /app
COPY . .
CMD kafka_2.13-3.4.0/bin/zookeeper-server-start.sh config/zookeeper.properties" > Dockerfile.zookeeper

echo "FROM openjdk:20-slim-buster
WORKDIR /app
COPY . .
CMD kafka_2.13-3.4.0/bin/kafka-server-start.sh config/server.properties" > Dockerfile.kafka
cd ..
echo "# the directory where the snapshot is stored.
dataDir=/tmp/zookeeper
# the port at which the clients will connect
clientPort=14000
# disable the per-ip limit on the number of connections since this is a non-production config
maxClientCnxns=0
# Disable the adminserver by default to avoid port conflicts.
# Set the port to something non-conflicting if choosing to enable this
admin.enableServer=false
# admin.serverPort=8080" > configfiles/zookeeper.properties
echo "version: \"3.3\"

services:
  zookeeper:
    image: zookeeper:latest
    volumes:
      - /opt/kafka-cluster/zookeeperdata/:/tmp/zookeeper/
      - /opt/kafka-cluster/configfiles/zookeeper.properties:/app/config/zookeeper.properties
    ports:
      - 14000:14000
  kafka:
    image: kafka-server:latest
    depends_on:
      - zookeeper
    volumes:
      - /opt/kafka-cluster/kafka-server-data/:/tmp/kafka-logs/
      - /opt/kafka-cluster/configfiles/kafka-server/server.properties:/app/config/server.properties
    ports:
      - 9092:9092" > docker-compose.yml
docker-compose up -d
mkdir configfiles/kafka-server
echo "broker.id=0
num.network.threads=3
num.io.threads=8
log.dirs=/tmp/kafka-logs
num.partitions=1
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.retention.check.interval.ms=300000
zookeeper.connect=localhost:14000
zookeeper.connection.timeout.ms=18000" > configfiles/kafka-server/server.properties
docker compose up -d kafka
yum install java-11* -y