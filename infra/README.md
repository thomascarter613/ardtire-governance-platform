# Infrastructure

This directory contains all Infrastructure as Code (IaC) for the Ardtire Governance Platform.

All files in this directory are scanned by [Checkov](https://www.checkov.io/) on every CI run
and on a weekly schedule. The policy configuration is in `.checkov.yaml` at the repository root.

## Structure

```
infra/
├── terraform/        # (planned) Terraform modules for VPS provisioning
├── ansible/          # (planned) Ansible playbooks for server configuration
└── scripts/          # (planned) Operational shell scripts
```

## Policy Enforcement

Checkov scans for:
- Exposed ports and insecure security group rules
- Unencrypted storage
- Missing resource tags
- Misconfigured IAM policies
- Docker / Compose misconfigurations
- GitHub Actions workflow security issues

Any HIGH or CRITICAL severity finding fails the CI pipeline.
Suppressions must be documented in `.checkov.yaml` with a justification comment.

## Adding Infrastructure

Before adding any IaC:
1. Review the [Architectural Constraints](../docs/architecture/constraints.md).
2. Open an ADR documenting the infrastructure decision.
3. Verify that `just policy-check` passes locally before pushing.
