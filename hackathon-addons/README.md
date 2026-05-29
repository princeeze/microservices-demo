# Hackathon add-ons (existing Online Boutique)

For clusters deployed with [official microservices-demo](../README.md) (`kubectl apply -f ./release/kubernetes-manifests.yaml`). **Additive only** — does not re-apply the full manifest or change other services.

## Cloud Armor (why Ingress / frontend?)

Cloud Armor attaches to **Google Cloud HTTP(S) load balancers**, not to individual pods or the whole cluster. Internal ClusterIP traffic (cart, checkout, etc.) stays off the internet and is not armored.

This add-on creates an **Ingress** in front of the existing `frontend` Service so **all external shop traffic** uses the Terraform policy `online-boutique-security-policy`. Other workloads are unchanged.

## One command

```bash
export GOOGLE_CLOUD_PROJECT=your-project-id
export REGION=us-central1
chmod +x apply.sh
./apply.sh
```

Skips the debug image build: `APPLY_DEBUG=0 ./apply.sh`

## Steps inside `apply.sh`

1. **RBAC** — `incident-console-sa` can rollout-restart `frontend`
2. **Ingress + BackendConfig** — Cloud Armor on external shop traffic
3. **Optional** — build `gcr.io/$PROJECT/frontend:hackathon` and `kubectl set image` only (adds `/debug/run`)

Debug API key: `defaultDebugAPIKey` in `../src/frontend/debug_handlers.go` (default `hackathon-debug-key-change-me`).

Shop URL after Ingress provisions:

```bash
kubectl get ingress boutique-ingress -o jsonpath='http://{.status.loadBalancer.ingress[0].ip}'
```
