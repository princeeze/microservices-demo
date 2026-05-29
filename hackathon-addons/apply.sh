#!/usr/bin/env bash
# Additive GKE updates: Cloud Armor via Ingress, optional /debug/run image (no full re-deploy).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="${GOOGLE_CLOUD_PROJECT:?Set GOOGLE_CLOUD_PROJECT}"
REGION="${REGION:-us-central1}"
IMAGE="${IMAGE:-gcr.io/${PROJECT}/frontend:hackathon}"
APPLY_DEBUG="${APPLY_DEBUG:-1}"

echo "=== RBAC (incident-console restart) ==="
sed "s/REPLACE_INCIDENT_CONSOLE_SA_EMAIL/incident-console-sa@${PROJECT}.iam.gserviceaccount.com/" \
  "$ROOT/remediation-rbac.yaml" | kubectl apply -f -

echo "=== Cloud Armor on shop ingress (external traffic only) ==="
kubectl apply -f "$ROOT/backend-config.yaml"
kubectl apply -f "$ROOT/frontend-ingress.yaml"
kubectl annotate service frontend \
  cloud.google.com/neg='{"ingress": true}' \
  cloud.google.com/backend-config='{"default": "frontend-backend-config"}' \
  --overwrite

if [ "$APPLY_DEBUG" = "1" ]; then
  echo "=== Build & roll frontend image (/debug/run) — deployment only ==="
  docker build -t "$IMAGE" "$ROOT/../src/frontend"
  docker push "$IMAGE"
  kubectl set image deployment/frontend server="$IMAGE"
  kubectl rollout status deployment/frontend --timeout=300s
fi

echo "=== Shop URL (Ingress IP may take 2–5 min) ==="
kubectl get ingress boutique-ingress -o jsonpath='http://{.status.loadBalancer.ingress[0].ip}{"\n"}' 2>/dev/null || true
echo "Debug key: see defaultDebugAPIKey in src/frontend/debug_handlers.go"
