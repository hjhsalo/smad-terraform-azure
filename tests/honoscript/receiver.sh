#!/bin/bash

info=./config.json

test -f $info || exit 1

KAFKA_IP=$(jq -r .KAFKA_IP < $info)
MY_TENANT=$(jq -r .MY_TENANT < $info)
KAFKA_TRUSTSTORE_PATH=$(jq -r .KAFKA_TRUSTSTORE_PATH < $info)

java -jar hono-cli-1.9.0-exec.jar \
--spring.profiles.active=receiver,local,kafka \
--tenant.id=$MY_TENANT \
--hono.kafka.commonClientConfig.bootstrap.servers=$KAFKA_IP:9094 \
--hono.kafka.commonClientConfig.security.protocol=SASL_SSL \
--hono.kafka.commonClientConfig.sasl.jaas.config="org.apache.kafka.common.security.scram.ScramLoginModule required username=\"hono\" password=\"hono-secret\";" \
--hono.kafka.commonClientConfig.sasl.mechanism=SCRAM-SHA-512 \
--hono.kafka.commonClientConfig.ssl.truststore.location=$KAFKA_TRUSTSTORE_PATH \ 
--hono.kafka.commonClientConfig.ssl.truststore.password=honotrust \
--hono.kafka.commonClientConfig.ssl.endpoint.identification.algorithm="" 
#--hono.client.username=consumer@HONO \
#--hono.client.password=verysecret \
