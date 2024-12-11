#!/bin/bash

YQ=./yq
config_file=./config.yaml

env_vars=""
for var in PROMTAIL GRAFANA PETSTORE PROMETHEUS; do
  value=$($YQ e ".ports.${var,,}" "$config_file")
  env_vars+="${var}_PORT=$value "
done
SSH_PORT=$($YQ e '.services[] | select(.name == "ssh") | .host_port' "$config_file")
ssh user@localhost -p "$SSH_PORT" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "sudo $env_vars  bash -s " < full-test.sh 