# GitOps Demo on GKE with Argo CD

This repository demonstrates GitOps-driven delivery of a multi-tier web application (frontend, backend, and PostgreSQL database) to Google Kubernetes Engine (GKE) using Helm, Argo CD, Terraform, and GitHub Actions.

## Repository Layout

- `apps/frontend/` – Static frontend site served by NGINX.
- `apps/backend/` – Node.js/Express API that talks to PostgreSQL.
- `docker-compose.yaml` – Local development stack.
- `helm/gitops-demo/` – Helm chart bundling frontend, backend, and database workloads.
- `infra/terraform/templates/` – Terraform templates used to generate manifests (Argo CD Application).
- `infra/terraform/` – Terraform configuration for provisioning a minimal GKE cluster.
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

## Helm Chart

The chart under `helm/gitops-demo` deploys the complete stack. Key values:

- `frontend.image.*` – Container image for the UI.
- `backend.image.*` – Container image for the API.
- `backend.database.*` – Database connection secret controls.
- `postgres.*` – PostgreSQL statefulset configuration.
- `ingress.*` – Host and paths (`/` → frontend, `/api` → backend).

Render or install locally with:

```bash
helm dependency update helm/gitops-demo  # noop, kept for future use
helm install gitops-demo helm/gitops-demo \
  --set frontend.image.repository="ghcr.io/YOUR_ORG/gitops-demo-frontend" \
  --set frontend.image.tag="dev" \
  --set backend.image.repository="ghcr.io/YOUR_ORG/gitops-demo-backend" \
  --set backend.image.tag="dev"
```

## Terraform – GKE Bootstrap

Terraform in `infra/terraform` provisions:

1. GKE API enablement.
2. A single-zone GKE cluster (`remove_default_node_pool = true`).
3. A managed node pool with a single `e2-standard-4` node.
4. An Artifact Registry (Docker) repository for container images.
5. An Argo CD control plane and a GitOps `Application` that points back to this repository.

### Usage

```bash
cd infra/terraform

# Provide project and authentication (assumes application-default creds)
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/gcloud/application_default_credentials.json"

cat > terraform.tfvars <<EOT
project_id   = "your-gcp-project"
region       = "us-central1"
zones        = ["us-central1-a"]
cluster_name = "gitops-demo"
gitops_repo_url = "https://github.com/YOUR_ORG/gitops-demo.git"
EOT

# Remote state is configured to use the GCS bucket `gs://gitops-project-tf-state`.
# Ensure that bucket (and the `gitops-demo/terraform-state` prefix) exists before initializing.
terraform init
terraform plan
terraform apply
```

Fetch cluster credentials:

```bash
$(terraform output -raw kubeconfig)
```

### Notes

- Requires Terraform >=1.13.0 (tested with 1.13.4) and Google provider ~> 6.0.
- Defaults use the `default` VPC/subnet; override `network` and `subnetwork` for production setups.
- Configure Google Cloud auth before running Terraform (`gcloud auth login` and `gcloud auth application-default login`).
- Consider enabling Workload Identity and hardened node configs for real environments.
- To use a different Terraform state bucket, edit `infra/terraform/versions.tf` and update the `backend "gcs"` block.

## Argo CD

Terraform installs Argo CD via the official Helm chart (`helm_release.argocd`) once the cluster is ready. Customize the deployment by setting values in `infra/terraform/terraform.tfvars`:

- `argocd_namespace` – Target namespace (default `argocd`).
- `argocd_chart_version` – Pin a specific chart release (leave `null` to track the latest available).
- `argocd_server_service_type` – Service type for the Argo CD API/server (`ClusterIP`, `LoadBalancer`, etc.).
- `argocd_image_repository` / `argocd_image_tag` – Override the Argo CD controller image. Leave unset to let the chart pull its latest defaults.
- `argocd_additional_values` – Extra YAML documents merged into the Helm chart values for advanced tuning.
- `gitops_repo_url` – Git repository Argo CD will sync (required).
- `gitops_repo_revision` – Branch/tag/commit to track (default `main`).
- `artifact_registry_location` / `artifact_registry_repository` – Where Terraform creates the Artifact Registry Docker repo.

After `terraform apply`, use the outputs/commands above to authenticate with the cluster, retrieve the initial admin password, and (optionally) port-forward the UI:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
kubectl -n argocd port-forward svc/argocd-server 8443:443
```

Terraform creates the Argo CD Application resource automatically (see `infra/terraform/argocd_app.tf`), so once the workflow merges new Helm values, Argo CD reconciles the chart without manual steps.

The Terraform output `artifact_registry_repository` prints the fully-qualified Artifact Registry hostname (`<region>-docker.pkg.dev/<project>/<repo>`). Use that value when retagging images or updating CI workflows if you choose to push images to Artifact Registry instead of GHCR.

## GitHub Actions Workflow

The workflow builds frontend and backend images on pushes to `main`, pushes to GHCR, then opens a PR updating Helm values with the new image tag (`${{ github.sha }}`). When the PR is merged, Argo CD reconciles the chart update into the cluster.

Secrets required:

- None for GHCR when using the default `GITHUB_TOKEN`.
- Add any additional registry credentials if you switch registries.

## Next Steps / Enhancements

- Add automated tests (unit/integration) for the backend and frontend.
- Integrate image scanning (`trivy`, `grype`) and policy checks (`conftest`, `kube-score`).
- Parameterize environments (dev/stage/prod) via Helm value overlays per namespace.
- Add lifecycle/retention policies to the Terraform state bucket and enable bucket object versioning.
