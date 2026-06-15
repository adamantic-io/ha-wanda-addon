#!/bin/sh
# Generates /etc/wanda/{agent,services}.yaml from the add-on options, then
# launches the Wanda agent daemon. Runs with host networking, so localhost
# inside this container is the Home Assistant host network stack.
set -e

OPT=/data/options.json

BASTION=$(jq -r '.bastion_address' "$OPT")
MID=$(jq -r '.machine_id' "$OPT")
INSECURE=$(jq -r '.tls_insecure' "$OPT")
HA_TARGET=$(jq -r '.ha_target' "$OPT")
SSH_TARGET=$(jq -r '.ssh_target // ""' "$OPT")

cat >/etc/wanda/agent.yaml <<EOF
proxy:
  address: "${BASTION}"
  tls:
    enabled: true
    insecure: ${INSECURE}
machine_id: "${MID}"
log_level: info
EOF

{
  echo "services:"
  echo "  - name: \"Home Assistant UI\""
  echo "    type: \"wanda:status\""
  echo "    target: \"${HA_TARGET}\""
  if [ -n "${SSH_TARGET}" ]; then
    echo "  - name: \"SSH\""
    echo "    type: \"remote-access\""
    echo "    target: \"${SSH_TARGET}\""
  fi
} >/etc/wanda/services.yaml

echo "wanda-agent: machine_id=${MID} bastion=${BASTION}"
exec wandad daemon
