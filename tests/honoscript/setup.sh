#!/bin/bash

declare -i  TIME=5

function die() { 
    echo "$@" >&2
    exit 13
}

function check_hono_cli() {
    echo '50d6699fa7893af7bfd3cc86df7e5e5488a255a2fbe35c154b23221f88abf134  hono-cli-1.9.0-exec.jar' | sha256sum -c --status
}

function hono_cli_install() {
    check_hono_cli && return 0

    curl -m $TIME -o hono-cli-1.9.0-exec.jar https://download.eclipse.org/hono/hono-cli-1.9.0-exec.jar || return 1

    check_hono_cli
}

hono_cli_install || die "Hono cli install failure"

which jq &> /dev/null || die "You're missing jq"
which curl &> /dev/null || die "Can't curl"
which pwgen &> /dev/null || die "Needs pwgen"
which mosquitto_pub &> /dev/null || die "Needs mosquitto-clients"

REGISTRY_IP=$(timeout $TIME kubectl get service hono-service-device-registry-ext -o json | jq -r .status.loadBalancer.ingress[0].ip)
HTTP_ADAPTER_IP=$(timeout $TIME kubectl get service hono-adapter-http-vertx -o json | jq -r .status.loadBalancer.ingress[0].ip)
MQTT_ADAPTER_IP=$(timeout $TIME kubectl get service hono-adapter-mqtt-vertx -o json | jq -r .status.loadBalancer.ingress[0].ip)
KAFKA_IP=$(timeout $TIME kubectl get service hono-kafka-0-external -o json | jq -r .status.loadBalancer.ingress[0].ip)
KAFKA_TRUSTSTORE_PATH=./truststore.jks 
kubectl get secrets hono-kafka-jks --template="{{index .data \"kafka.truststore.jks\" | base64decode}}" -n default > $KAFKA_TRUSTSTORE_PATH

AMQP_NETWORK_IP=$(timeout $TIME kubectl get service hono-dispatch-router-ext -o json | jq -r .status.loadBalancer.ingress[0].ip)
: ${REGISTRY_IP:?'Could not find registry ip'}
: ${HTTP_ADAPTER_IP:?'Could not find HTTP adapter ip'}
: ${MQTT_ADAPTER_IP:?'Could not find MQTT adapter ip'}
: ${AMQP_NETWORK_IP:?'Could not find AMQP network ip'}
: ${KAFKA_IP:?'Could not find KAFKA network ip'}

#echo $REGISTRY_IP
#echo $HTTP_ADAPTER_IP
#echo $MQTT_ADAPTER_IP
#echo $AMQP_NETWORK_IP

MY_TENANT=$(curl -m $TIME -X POST -H "content-type: application/json" http://$REGISTRY_IP:28080/v1/tenants --data-binary '{
  "ext": {
    "messaging-type": "kafka"
  }
}' 2> /dev/null | jq -r .id )
: ${MY_TENANT:?'Your tenant has moved out. Could not set MY_TENANT'}
test ${#MY_TENANT} = 36 || die "MY_TENANT is the wrong size. Does not have 36 characters"

MY_DEVICE=$(curl -m $TIME -X POST http://$REGISTRY_IP:28080/v1/devices/$MY_TENANT 2> /dev/null | jq -r .id)
: ${MY_DEVICE:?'Your device has left the building. Could not set MY_DEVICE'}
test ${#MY_DEVICE} = 36 || die "MY_DEVICE doesn't fit. Does not have 36 characters"

MY_PWD=$(timeout $TIME pwgen -s 15 1)
: ${MY_PWD:?'Password generation failed'}
test ${#MY_PWD} = 15 || die "Your password does not have 15 characters"

body=$(cat <<BODY
[
    {
        "type":"hashed-password",
        "auth-id": "${MY_DEVICE}",
        "secrets": [
            {
                "pwd-plain": "${MY_PWD}"
            }
        ]
    }
]
BODY
)

curl -m $TIME -f -X PUT \
    -H 'content-type: application/json' \
    --data-binary "$body" \
    http://$REGISTRY_IP:28080/v1/credentials/$MY_TENANT/$MY_DEVICE || die "could not set password so curling failed"



cat > config.json <<JSON
{
    "REGISTRY_IP": "${REGISTRY_IP}",
    "HTTP_ADAPTER_IP": "${HTTP_ADAPTER_IP}",
    "MQTT_ADAPTER_IP": "${MQTT_ADAPTER_IP}",
    "AMQP_NETWORK_IP": "${AMQP_NETWORK_IP}",
    "KAFKA_IP": "${KAFKA_IP}",
    "MY_TENANT": "${MY_TENANT}",
    "MY_DEVICE": "${MY_DEVICE}",
    "MY_PWD": "${MY_PWD}",
    "KAFKA_TRUSTSTORE_PATH": "${KAFKA_TRUSTSTORE_PATH}"
}
JSON
