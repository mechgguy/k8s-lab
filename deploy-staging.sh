#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="staging"
DEPLOYMENT_NAME="web-app"
MANIFEST="staging-deployment.yaml"

echo "[1/3] Applying manifest ${MANIFEST} to namespace ${NAMESPACE}..."
kubectl apply -f "${MANIFEST}"

echo "[2/3] Waiting for rollout of deployment/${DEPLOYMENT_NAME}..."
kubectl rollout status "deployment/${DEPLOYMENT_NAME}" -n "${NAMESPACE}" --timeout=120s

echo "[3/3] Current Pods and rollout history in ${NAMESPACE}:"
kubectl get pods -n "${NAMESPACE}" -o wide
kubectl rollout history "deployment/${DEPLOYMENT_NAME}" -n "${NAMESPACE}"
