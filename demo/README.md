# Local engineering project-management demo

This demo mode runs the repository's committed Vue build against deterministic in-memory API responses. It is intended for a stable course demonstration when Java, Maven, MySQL, Redis, Nacos, Seata, or external cloud services are unavailable.

## Start

Requirements: Node.js 18 or newer. No package installation is required.

```bash
./scripts/start-local-demo.sh
```

Open `http://127.0.0.1:4173`. Any non-empty username and password can be used on the local login screen.

The server listens on loopback by default and does not contact cloud services. Override `HOST` or `PORT` only when needed:

```bash
PORT=8080 ./scripts/start-local-demo.sh
```

## Verify

```bash
npm run demo:check
```

The check starts an isolated ephemeral server and verifies the frontend, authentication bootstrap, routes, dashboard statistics, project list, task list, and workflow queue.

## Render the screen-only demo

```bash
npm run demo:record
```

This recreates the 4 minute 30 second, 1080p recording from clean interface captures, eased mouse movement, and click-driven zooms. The final MP4 and its timing manifest are written to `output/`. See `demo/recording/README.md` for the shot list and rendering details.

## Demo data and limitations

- Data is reset every time the process restarts.
- The intended recording path is read-only: dashboard, projects, tasks, pending approvals, and completed approvals.
- Mutation endpoints return safe local success responses, but the mock does not persist changes.
- The full microservice deployment guide remains in `docs/local-startup-and-demo-guide.md` for environments with Java and infrastructure services.

Generated based on `@pmhub-ui`, `@pmhub-modules/pmhub-system`, `@pmhub-modules/pmhub-project`, `@pmhub-modules/pmhub-workflow`, and `@docs/local-startup-and-demo-guide.md`.
