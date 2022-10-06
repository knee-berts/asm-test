#!/usr/bin/env bash

set -Euo pipefail

echo "Test cross cluster discovery."
echo "Getting the whereami frontend external loadbalancer IP for cluster $(kubectx -c)."
FRONTEND_IP=$(kubectl get services -n whereami -l app=whereami-frontend -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo ${FRONTEND_IP}

FRONTEND_ZONE=$(curl -s ${FRONTEND_IP} | jq .zone)
BACKEND_ZONE=$(curl -s ${FRONTEND_IP} | jq .backend_result.zone)
while [[ ${FRONTEND_ZONE} == ${BACKEND_ZONE} ]]; do
  BACKEND_ZONE=$(curl -s ${FRONTEND_IP} | jq .backend_result.zone)
  FRONTEND_ZONE=$(curl -s ${FRONTEND_IP} | jq .zone)
  echo "Frontend zone: ${FRONTEND_ZONE}, Backend zone: ${BACKEND_ZONE}"
  sleep 1
done
echo "Frontend running in zone ${FRONTEND_ZONE} successfully routed to a backend in zone ${BACKEND_ZONE}. Cross Cluster Service Discovery is functioning."
