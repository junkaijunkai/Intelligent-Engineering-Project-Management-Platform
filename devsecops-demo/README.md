# DevSecOps Demo Evidence

This directory contains a time-bounded, manually triggered evidence pipeline for the DevSecOps demo.

## Scope

- The frontend demo container is the primary integration, load, container, and DAST target.
- The gateway container is optional evidence and never blocks the primary evidence package.
- Security findings are retained as evidence; missing or invalid reports fail verification.
- Generated reports are written to `out/` and are never committed.

## Local execution

```bash
bash devsecops-demo/scripts/run-all.sh
```

## GitHub execution

Push the committed workflow, then run **DevSecOps Demo Evidence** manually from the GitHub Actions page.
