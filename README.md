## Frontend GitOps

This repository defines the production Kubernetes workloads for the voting frontend. ArgoCD discovers the Helm charts under `apps/*` and deploys them to the `frontend-prod` namespace through the production ApplicationSet.

The application source repositories build the images. The [`vote-app`](https://github.com/YOUR_GITHUB_ORG/vote-app) and [`results-app`](https://github.com/YOUR_GITHUB_ORG/results-app) CD workflows update the image tags in this repository after their changes are merged.

## Managed Applications

| Application | Image | External path | Deployment behavior |
|-------------|-------|---------------|---------------------|
| `voting-vote` | `${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/voting-vote:<git-sha>` | `/vote` | Argo Rollouts blue/green |
| `voting-results` | `${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/voting-results:<git-sha>` | `/results` | Argo Rollouts blue/green |

Both charts use ClusterIP services on port `8080` with containers listening on port `80`. The applications run as non-root UID/GID `999`, use team node affinity and read shared connection configuration from ConfigMaps. Redis and database credentials are supplied through Kubernetes Secrets managed by the platform and data layers.

The HTTPRoutes attach to the `pub-gateway` in the `platform-prod` namespace. The results route rewrites `/results` to `/` before sending traffic to the results service. The vote route preserves the `/vote` prefix.

## Rollouts and Operations

Each frontend chart creates an active service and a preview service. `autoPromotionEnabled` is `false`, so a new ReplicaSet can be tested through the preview service before it is promoted. Horizontal Pod Autoscalers allow one to five replicas with CPU and memory targets of 60 percent. PodDisruptionBudgets require at least one available replica.

The vote chart exposes `/metrics` for Prometheus scraping. The results chart provides the results endpoint and uses its configured base path. Service monitors and Grafana dashboard resources are maintained alongside the relevant chart where required.

## Validation

Pull requests run the repository workflow in [`.github/workflows/ci-lint.yml`](.github/workflows/ci-lint.yml). It runs Gitleaks, Helm lint and Kubeconform validation for the `apps` and `bootstrap` directories:

```bash
helm lint -f=prod-values.yml apps/<application>
helm template apps/<application> -f prod-values.yml | kubeconform -ignore-missing-schemas -strict
```

After a change is merged, ArgoCD watches the `main` branch and applies the generated Helm resources. See the [umbrella GitOps guide](https://github.com/YOUR_GITHUB_ORG/aws-eks-gitops-argocd-terraform/blob/main/GitOps/README.md) for the platform-wide workflow and the [platform GitOps repository](https://github.com/YOUR_GITHUB_ORG/platform-gitops) for shared controllers and ArgoCD Projects.
