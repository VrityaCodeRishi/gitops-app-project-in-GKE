# GitOps Demo on GKE with Argo CD

This repository demonstrates GitOps-driven delivery of a multi-tier web application (frontend, backend, and PostgreSQL database) to Google Kubernetes Engine (GKE) using Helm, Argo CD, Terraform, and GitHub Actions.

## Repository Layout

- `apps/frontend/` – Static frontend site served by NGINX.
- `apps/backend/` – Node.js/Express API that talks to PostgreSQL.
- `docker-compose.yaml` – Local development stack.
- `helm/gitops-demo/` – Helm chart bundling frontend, backend, and database workloads.
- `helm/monitoring/` – Monitoring stack (Prometheus, Loki, Grafana Alloy) packaged for GitOps deployment.
- `infra/terraform-cluster/` – Terraform module that provisions the GKE cluster and Artifact Registry.
- `infra/terraform-apps/` – Terraform module that installs Argo CD and registers GitOps applications.
- `infra/env/` – Terragrunt configurations orchestrating cluster/app modules.
- `.github/workflows/gitops.yaml` – CI workflow that builds/pushes container images and opens a PR with Helm value updates.

## Local Development

```bash
# Frontend + backend + Postgres
docker compose up --build

# Access the UI
open http://localhost:3000
# Backend health
curl http://localhost:8080/api/health
```

## Container Images

Each service has a separate Dockerfile in its directory. Example build commands:

```bash
docker build -t ghcr.io/YOUR_ORG/gitops-demo-frontend:dev apps/frontend

docker build -t ghcr.io/YOUR_ORG/gitops-demo-backend:dev apps/backend
```

Push the images to your registry of choice (GHCR is assumed in the workflow).
Container registry repository names must be lowercase; the GitHub Actions workflow normalizes the GitHub owner name accordingly.

## Helm Chart

The chart under `helm/gitops-demo` deploys the complete stack. Key values:

- `frontend.image.*` – Container image for the UI.
- `backend.image.*` – Container image for the API.
- `backend.database.*` – Database connection secret controls.
- `backend.monitoring.*` – Flags for enabling the ServiceMonitor that exposes `/metrics`.
- `postgres.*` – PostgreSQL statefulset configuration.
- `ingress.*` – Host and paths (`/` → frontend, `/api` → backend).

Render or install locally with:

```bash
helm dependency update helm/gitops-demo  # noop, kept for future use
helm install gitops-demo helm/gitops-demo \
  --set frontend.image.repository="ghcr.io/your_org/gitops-demo-frontend" \
  --set frontend.image.tag="dev" \
  --set backend.image.repository="ghcr.io/YOUR_ORG/gitops-demo-backend" \
  --set backend.image.tag="dev"
```

## Terraform & Terragrunt

Provisioning is split into two Terraform modules orchestrated by Terragrunt:

1. `terraform-cluster` – enables APIs, creates the Artifact Registry repo, and provisions the GKE cluster/node pool.
2. `terraform-apps` – installs Argo CD via Helm.
3. `terraform-gitops` – registers the GitOps applications (app + monitoring) once Argo CD CRDs are present.

Terragrunt handles ordering (cluster first, then apps) and remote state layouts.

### Usage

```bash
cd infra/env/default

# Authenticate with Google Cloud (assumes application-default credentials)
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

# Run both stacks (cluster first, then apps)
terragrunt run init
terragrunt run apply

# Destroy everything when done
terragrunt run destroy

# Fetch kubeconfig command from the cluster stack
terragrunt run --terragrunt-working-dir env/default/cluster output -raw kubeconfig
```

### Notes

- Requires Terraform >=1.13.0 (tested with 1.13.4) and Google provider ~> 6.0.
- Defaults use the `default` VPC/subnet; override `network` and `subnetwork` for production setups.
- Configure Google Cloud auth before running Terragrunt (`gcloud auth login` and `gcloud auth application-default login`).
- To use a different Terraform state bucket, edit `infra/terragrunt.hcl` and adjust the `remote_state` settings.
- Toggle monitoring by setting `enable_monitoring = false` in `infra/env/default/gitops/terragrunt.hcl` inputs if you want to skip Prometheus/Loki/Grafana Alloy.

## Argo CD

The `terraform-apps` module installs Argo CD via Helm (customize chart options in `infra/env/default/apps/terragrunt.hcl`). The `terraform-gitops` module applies the Argo CD `Application` resources; tweak the repo path or monitoring toggle in `infra/env/default/gitops/terragrunt.hcl`.

Once Terragrunt finishes, port-forward the UI and grab the initial password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl -n argocd port-forward svc/argocd-server 8443:443
```

### Monitoring Stack

With `enable_monitoring = true`, the apps module provisions a second Argo CD Application (`monitoring`) that deploys `helm/monitoring`. This chart wraps:

- `kube-prometheus-stack` for Prometheus, Alertmanager (disabled by default), Grafana, node exporter, and kube-state-metrics.
- `loki-stack` for log aggregation (Promtail disabled in favour of Alloy).
- `grafana/alloy` running as a DaemonSet to ship Kubernetes container logs into Loki.

Key behaviors:

- The backend now exposes Prometheus metrics at `/metrics` (ported through port 8080). The Helm chart ships a `ServiceMonitor` so `kube-prometheus-stack` scrapes it automatically.
- Grafana is available inside the cluster via the `monitoring-stack-grafana` service (`port-forward`: `kubectl -n monitoring port-forward svc/monitoring-stack-grafana 3000:80`). Default credentials are `admin / gitops-demo`.
- Loki is reachable inside the cluster at `http://monitoring-loki:3100`. Grafana is pre-configured with Prometheus and Loki data sources, and Alloy automatically streams Kubernetes pod logs into Loki.

## GitHub Actions Workflow

The workflow builds frontend and backend images on pushes to `main`, pushes them to GHCR, then commits updated Helm values directly to `main` (skipping automated changes when the actor is already the GitHub Actions bot). Argo CD detects the updated tag values and reconciles the chart.

Secrets required:

- None for GHCR when using the default `GITHUB_TOKEN`.
- Add any additional registry credentials if you switch registries.
