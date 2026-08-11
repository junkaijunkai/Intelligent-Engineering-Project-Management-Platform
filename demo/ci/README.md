# Demo-safe CI/CD

This pipeline gives the internship demonstration a reliable localhost CI/CD console without pretending that the full microservice platform has been deployed to a public environment.

## What it proves

1. The committed frontend, deterministic mock API, narration, and local runner are present.
2. The mock API contract passes its automated Node.js tests.
3. The local runner assembles a delivery manifest for the self-contained demo bundle.
4. The console starts the app on localhost and smoke-tests the frontend, login, dashboard, projects, and workflow queue.
5. The browser dashboard shows stage status, logs, artifacts, and the local staging link.

No Maven, database, Redis, Docker registry, cloud host, repository secret, or package installation is required.

## Local console

```bash
npm run demo:ci
```

Open `http://127.0.0.1:4180`. The pipeline runs automatically and leaves the staging app available at `http://127.0.0.1:4173`. Generated evidence is written to `demo-ci-artifacts/` and ignored by Git.

## Command-line rehearsal

```bash
npm run demo:pipeline
```

The repository's existing GitHub workflows are unchanged. This fallback does not require GitHub, Maven, Docker, a registry, or any repository secret.
