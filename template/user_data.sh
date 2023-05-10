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
CMD ./bin/zookeeper-server-start.sh config/zookeeper.properties" > Dockerfile.zookeeper
echo "FROM openjdk:20-slim-buster
WORKDIR /app
COPY . .
CMD ./bin/zookeeper-server-start.sh config/zookeeper.properties" > Dockerfile.kafka
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
echo "version: "3.9"

networks:
  default:
    name: kafka
    driver: bridge

volumes:
  zookeeperdata:

services:
  zookeeper:
    build:
      context: kafka_2.13-3.4.0
      dockerfile: ../dockerfiles/Dockerfile.zookeeper
    volumes:
      - zookeeperdata:/tmp/zookeeper
      - ./configfiles/zookeeper.properties:/app/config/zookeeper.properties
  kafka:
    build: 
      context: kafka_2.13-3.4.0
      dockerfile: ../dockerfiles/Dockerfile.kafka
    volumes:
      - kafka-server-data:/tmp/kafka-logs
      - ./configfiles/kafka-server/server.properties:/app/config/server.properties
    ports:
      - 4000:4000" > docker-compose.yml
docker-compose up -d --build zookeeper
mkdir configfiles/kafka-server
echo "broker.id=0
zookeeper.connect=zookeeper:14000
zookeeper.connection.timeout.ms=18000
sasl.enabled.mechanisms=PLAIN
sasl.mechanism.inter.broker.protocol=PLAIN
listener.name.internal.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
 username="admin" \
 password="admin-secret" \
 user_admin="admin-secret";

listener.name.external.plain.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
     username="admin" \
     password="admin-secret" \
 user_admin="admin-secret";

listeners=INTERNAL://:9092,EXTERNAL://:4000
advertised.listeners=INTERNAL://leesin:9092,EXTERNAL://10.0.2.15:4000
inter.broker.listener.name=INTERNAL
listener.security.protocol.map=INTERNAL:SASL_PLAINTEXT,EXTERNAL:SASL_PLAINTEXT
num.network.threads=3
num.io.threads=8
socket.send.buffer.bytes=102400
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
log.dirs=/tmp/kafka-logs
num.partitions=3
num.recovery.threads.per.data.dir=1
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
log.flush.interval.messages=10000
log.flush.interval.ms=1000
log.retention.hours=168
log.segment.bytes=1073741824
log.retention.check.interval.ms=300000
group.initial.rebalance.delay.ms=0" > configfiles/kafka-server/server.properties
docker compose up -d kafka
