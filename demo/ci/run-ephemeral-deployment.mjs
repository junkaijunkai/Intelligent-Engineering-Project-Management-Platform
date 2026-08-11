#!/usr/bin/env node

import { appendFile, mkdir, writeFile } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

import { createDemoServer } from "../mock-server.mjs"

const ciDir = path.dirname(fileURLToPath(import.meta.url))
const projectRoot = path.resolve(ciDir, "../..")
const evidenceDir = path.join(projectRoot, "demo-ci-artifacts")
const server = createDemoServer()

await new Promise((resolve, reject) => {
  server.once("error", reject)
  server.listen(0, "127.0.0.1", resolve)
})

const address = server.address()
const baseUrl = `http://127.0.0.1:${address.port}`
const checks = []

async function check(name, pathname, options, validate) {
  const response = await fetch(`${baseUrl}${pathname}`, options)
  if (!response.ok) throw new Error(`${name} returned HTTP ${response.status}`)
  const body = await response.text()
  const parsed = response.headers.get("content-type")?.includes("json") ? JSON.parse(body) : body
  if (!validate(parsed)) throw new Error(`${name} returned an unexpected contract`)
  checks.push({ name, path: pathname, status: response.status })
}

try {
  await check("frontend", "/", undefined, (body) => body.includes("<title>Engineering Project Management</title>"))
  await check(
    "login",
    "/prod-api/auth/login",
    { method: "POST", headers: { "Content-Type": "application/json" }, body: '{"username":"demo","password":"demo"}' },
    (body) => body.code === 200 && body.token === "pmhub-local-demo-token",
  )
  await check("dashboard", "/prod-api/project/statistics", undefined, (body) => body.data?.projectNum === 3)
  await check("projects", "/prod-api/project/list", { method: "POST" }, (body) => body.data?.total === 3)
  await check("workflow", "/prod-api/workflow/process/todoList", undefined, (body) => body.total === 2)
} finally {
  await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())))
}

const evidence = {
  deployment: "pmhub-demo-local-staging",
  status: "healthy",
  commit: process.env.GITHUB_SHA || "local",
  environment: process.env.GITHUB_ACTIONS ? "github-actions-ephemeral-runner" : "local-ephemeral-runner",
  persistence: "process lifetime only",
  publicCloudEndpoint: false,
  checks,
}

await mkdir(evidenceDir, { recursive: true })
await writeFile(
  path.join(evidenceDir, "deployment-evidence.json"),
  `${JSON.stringify(evidence, null, 2)}\n`,
)

if (process.env.GITHUB_STEP_SUMMARY) {
  const rows = checks.map((item) => `| ${item.name} | \`${item.path}\` | ${item.status} |`).join("\n")
  await appendFile(
    process.env.GITHUB_STEP_SUMMARY,
    `## Local demo deployment\n\nThe tracked demo bundle was deployed to an isolated runner and shut down after validation. No cloud service or repository secret was used.\n\n| Check | Route | HTTP |\n| --- | --- | ---: |\n${rows}\n`,
  )
}

console.log(`Ephemeral deployment passed ${checks.length} smoke checks and was shut down cleanly.`)
