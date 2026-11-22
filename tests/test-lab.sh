#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] Validating shell scripts..."
bash -n deploy-staging.sh
bash -n tests/test-lab.sh

echo "[2/3] Validating YAML syntax across repo..."
python3 -c '
import glob, yaml
files = sorted(glob.glob("*.yaml") + glob.glob("iac/*.yaml") + glob.glob("gitops/*.yaml"))
assert files, "No YAML files found"
for f in files:
    with open(f) as fh:
        docs = [d for d in yaml.safe_load_all(fh) if d is not None]
    assert docs, f"No YAML documents in {f}"
    print(f"  OK YAML: {f}")
'

echo "[3/3] Checking RBAC least-privilege and Service selector..."
python3 -c '
import yaml

with open("role-ci-deployer.yaml") as fh:
    role = yaml.safe_load(fh)
assert role["kind"] == "Role"
assert role["metadata"]["namespace"] == "staging"
for rule in role.get("rules", []):
    assert "secrets" not in rule.get("resources", []), "Role must not grant access to secrets"
    assert "*" not in rule.get("resources", []), "Role must not use wildcard resources"

with open("staging-service.yaml") as fh:
    svc = yaml.safe_load(fh)
assert svc["kind"] == "Service"
svc_type = svc.get("spec", {}).get("type", "ClusterIP")
assert svc_type == "ClusterIP", f"Expected ClusterIP, got {svc_type}"
assert svc.get("spec", {}).get("selector", {}).get("app") == "web-app"
print("  OK RBAC and Service checks passed")
'
