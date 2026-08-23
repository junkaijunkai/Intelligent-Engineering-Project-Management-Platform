# DevSecOps Evidence Helpers

This directory contains scripts and configuration used by the project-wide DevSecOps CI workflow.

## Scope

- The full backend Docker Compose environment is the CI runtime target.
- Gateway is the single HTTP entrypoint for integration, load, and DAST checks.
- Security findings are retained as evidence; missing or invalid reports fail verification.
- Generated reports are written to `out/` and are never committed.

## Local execution

```bash
bash ci/scripts/run-all.sh
```

## GitHub execution

The unified workflow is `.github/workflows/devsecops.yml`; reusable CI scripts and configuration live under `ci/`.
It builds and scans all backend service images, starts the full Compose runtime on a hosted
runner, and uploads project-level evidence. OWASP, SonarCloud, and DAST are manual options.
