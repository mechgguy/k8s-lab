# Local Kubernetes Lab: Multi-Node `kind`, RBAC, Service & Git-Triggered Rollouts

A hands-on local Proof of Concept (POC) built on Ubuntu using `kind` and Docker to practice Kubernetes architecture, least-privilege RBAC, internal `Service` routing/DNS, and automated rollouts triggered by Git commits.

## Repository Structure

| File | Description |
| :--- | :--- |
| `kind-2node.yaml` | Active 2-node cluster configuration (`control-plane` + `worker`) using `kindest/node:v1.31.2`. |
| `kind-3node.yaml` | 3-node cluster configuration kept for reference/experimentation. |
| `role-ci-deployer.yaml` | Defines the `deployment-manager` `Role` scoped to the `staging` namespace (`pods` and `deployments`). |
| `rolebinding-ci-deployer.yaml` | Binds the `ci-deployer` `ServiceAccount` to `deployment-manager` inside `staging`. |
| `staging-deployment.yaml` | Defines the `web-app` `Deployment` (`nginx` container, `serviceAccountName: ci-deployer`). |
| `staging-service.yaml` | Exposes `web-app` internally via a `ClusterIP` `Service` (`web-app.staging.svc.cluster.local`). |
| `deploy-staging.sh` | Applies `staging-deployment.yaml`, waits for rollout completion, and prints Pods and rollout history. |
| `.gitignore` | Ignores backup files, editor artifacts, and local secret/kubeconfig files. |

*(Note: `.git/hooks/post-commit` is stored locally inside `.git/hooks/` and is not pushed automatically by `git push`—see setup steps below.)*

## What Was Built & Verified

1. **Multi-Node Cluster (`kind`):** Spun up `dev-cluster` with a control-plane node and worker node under tight memory and cgroup v1 constraints.
2. **Least-Privilege RBAC:** Created the `staging` namespace and `ci-deployer` `ServiceAccount`, granted scoped access via `Role` and `RoleBinding`, and verified that listing `secrets` is `Forbidden`.
3. **Internal Service & DNS:** Created `staging-service.yaml` (`ClusterIP`), verified `Endpoints` match running `web-app` Pod IPs, tested HTTP `200 OK` via `http://web-app.staging.svc.cluster.local`, and watched `Endpoints` update dynamically as replicas scaled (`1` -> `2` -> `1`).
4. **Git-Triggered Deployment Loop:** Wired `.git/hooks/post-commit` to execute `./deploy-staging.sh` automatically after commits.

## Local Hook Setup (After Cloning)

Git does not clone hooks inside `.git/hooks/` automatically. To enable the local hook after cloning on another machine:

```bash
cat <<'EOF' > .git/hooks/post-commit
#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
echo "Post-commit hook triggered: running ./deploy-staging.sh..."
./deploy-staging.sh
