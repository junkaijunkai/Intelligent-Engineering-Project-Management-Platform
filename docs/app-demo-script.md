# PmHub App Demo script (about 4 minutes 30 seconds)

This script is designed for a screen-only recording. Use the local deterministic demo, keep the browser at 100% zoom, and do not type real credentials or show unrelated tabs.

## Before recording

1. Run `./scripts/start-local-demo.sh` and open `http://127.0.0.1:4173`.
2. If the login screen appears, sign in with `demo` / `demo`. These values stay on this Mac and are accepted only by the local mock server. Start recording after the dashboard appears.
3. Confirm that the dashboard shows 3 projects, 18 tasks, 4 tasks today, and 1 overdue task.
4. Close unrelated tabs and notifications. Restart the local demo if you want to reset the data.

## 00:00–00:30 — Purpose and dashboard

**On screen:** Start on the PmHub dashboard. Move the cursor once across the four summary cards, then briefly indicate the project-progress and task-status charts.

**Narration:**

> This is my intelligent engineering project management platform. It brings project delivery, task execution, and approval workflows into one operational view. The dashboard gives a concise management baseline: three active project records, eighteen tasks, today's workload, and the current overdue exposure. The charts then show delivery progress by project and the distribution of task status.

## 00:30–01:25 — Project portfolio

**On screen:** Click **项目管理 → 我的项目**. Pause on the populated table. Point to project code, stage, status, progress, owner, and deadline. Use the status filter once and reset it.

**Narration:**

> The project portfolio provides one governed list instead of separate spreadsheets. Each project has a stable code, lifecycle stage, publication state, progress, accountable owner, and target completion date. The filters support quick management review by status, project type, or time range. Here, the Smart Campus platform is in integration and validation at seventy-eight percent, while the completed handover workflow remains available as historical evidence.

## 01:25–02:25 — Execution and risk

**On screen:** Click **项目管理 → 我的任务**. Pause on the task rows. Indicate project, stage, executor, state, priority, deadline, and progress. Filter the project dropdown to **Smart Campus Delivery Platform**, then reset to all projects.

**Narration:**

> Project commitments are decomposed into traceable tasks. The task view connects every item to its project and stage, then records the executor, execution state, priority, deadline, and percentage complete. This makes delivery risk visible before a deadline is missed. The highest-priority item is the schedule-risk prediction validation, which is in progress at seventy-two percent, while sponsor acceptance evidence is already planned for the handover stage.

## 02:25–03:25 — Workflow governance

**On screen:** Click **我的事务 → 待办任务**. Point to the two approval rows, including task number, process, current node, initiator, and received time. Do not submit an approval. Then click **已办任务** and pause on the audit history.

**Narration:**

> Governance is integrated into the same platform. The pending queue shows the process definition, current approval node, initiator, department, and waiting time. This supports project-gate approval and controlled handling of risk exceptions. The completed queue preserves the approval timestamp and elapsed duration, providing a clear audit trail from request to decision without relying on email threads.

## 03:25–04:10 — Architecture and deterministic demonstration

**On screen:** Return to the dashboard. Keep the navigation and populated charts visible.

**Narration:**

> In the full architecture, the Vue client calls a Spring Cloud gateway, with project, system, and workflow services separated by business domain. Nacos, Redis, MySQL, and Flowable support discovery, session state, persistence, and workflow execution. For this recording, those external services are replaced by deterministic local data, so the demonstrated interface and navigation remain stable and no confidential or cloud-hosted data is exposed.

## 04:10–04:30 — Close

**On screen:** Rest the cursor beside the progress chart and hold the frame for three seconds.

**Narration:**

> The platform therefore connects portfolio visibility, accountable execution, proactive risk awareness, and auditable approval in one place. The result is faster status review, clearer ownership, and more reliable delivery evidence.

Generated based on `@pmhub-ui`, `@sql/pmhub-system.sql`, `@docs/project-notes.md`, and `@docs/local-startup-and-demo-guide.md`; recording structure adapted from the CineX App Demo requirement of a concise working-system demonstration.
