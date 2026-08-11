#!/usr/bin/env node

import { execFile, execFileSync } from "node:child_process"
import { createHash } from "node:crypto"
import { createReadStream } from "node:fs"
import { mkdir, readFile, stat, writeFile } from "node:fs/promises"
import { createServer } from "node:http"
import path from "node:path"
import { fileURLToPath } from "node:url"

import { createDemoServer } from "../mock-server.mjs"

const ciDir = path.dirname(fileURLToPath(import.meta.url))
const projectRoot = path.resolve(ciDir, "../..")
const evidenceDir = path.join(projectRoot, "demo-ci-artifacts")
const dashboardPath = path.join(ciDir, "dashboard.html")
const dashboardHost = process.env.CI_HOST || "127.0.0.1"
const dashboardPort = Number(process.env.CI_PORT || 4180)
const stagingHost = process.env.HOST || "127.0.0.1"
const stagingPort = Number(process.env.PORT || 4173)
const stagingUrl = `http://${stagingHost}:${stagingPort}`

const branch = runGit(["branch", "--show-current"]) || "local"
const commit = runGit(["rev-parse", "--short", "HEAD"]) || "working-tree"
const stages = [
  stage("source", "Source Contract", "Verify the tracked UI, demo data, script, and local runner"),
  stage("tests", "API Test Gate", "Run deterministic login, routing, project, task, and workflow tests"),
  stage("package", "Assemble Artifact", "Create a local delivery manifest with content fingerprints"),
  stage("deploy", "Deploy Staging", "Start the interactive application on the localhost staging port"),
  stage("smoke", "Runtime Smoke", "Exercise the deployed frontend and five business endpoints"),
  stage("release", "Release Gate", "Publish local evidence and mark the demo ready to record"),
]

const pipeline = {
  name: "Internship Demo Delivery",
  build: 1,
  status: "idle",
  branch,
  commit,
  stagingUrl,
  startedAt: null,
  finishedAt: null,
  stages,
  logs: [],
  artifacts: [
    { name: "Interactive staging app", href: stagingUrl, kind: "deployment" },
    { name: "Bundle manifest", href: "/artifacts/bundle-manifest.json", kind: "artifact" },
    { name: "Delivery evidence", href: "/artifacts/pipeline-evidence.json", kind: "evidence" },
  ],
}

let pipelineRunning = false
let stagingServer
let ownsStagingServer = false

function stage(id, name, description) {
  return { id, name, description, status: "queued", startedAt: null, finishedAt: null, detail: "Waiting" }
}

function runGit(args) {
  try {
    return execFileSync("git", args, { cwd: projectRoot, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim()
  } catch {
    return ""
  }
}

function log(message, level = "info") {
  const time = new Date().toISOString().slice(11, 19)
  pipeline.logs.push({ time, level, message })
  if (pipeline.logs.length > 160) pipeline.logs.shift()
  console.log(`[${time}] ${message}`)
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds))
}

function execute(command, args) {
  return new Promise((resolve, reject) => {
    execFile(command, args, { cwd: projectRoot, encoding: "utf8", maxBuffer: 8 * 1024 * 1024 }, (error, stdout, stderr) => {
      for (const line of `${stdout || ""}\n${stderr || ""}`.split("\n").map((item) => item.trim()).filter(Boolean)) log(line)
      if (error) reject(error)
      else resolve()
    })
  })
}

async function runStage(id, action) {
  const item = pipeline.stages.find((candidate) => candidate.id === id)
  item.status = "running"
  item.startedAt = new Date().toISOString()
  item.detail = "Running"
  log(`${item.name} started`)
  await delay(650)
  await action(item)
  await delay(450)
  item.status = "passed"
  item.finishedAt = new Date().toISOString()
  if (item.detail === "Running") item.detail = "Passed"
  log(`${item.name} passed`, "success")
}

async function createBundleManifest() {
  const files = [
    "package.json",
    "demo/mock-server.mjs",
    "demo/ci/local-pipeline-server.mjs",
    "pmhub-ui/dist/index.html",
    "docs/app-demo-script.md",
  ]
  const entries = []
  for (const relativePath of files) {
    const absolutePath = path.join(projectRoot, relativePath)
    const contents = await readFile(absolutePath)
    entries.push({
      path: relativePath,
      bytes: (await stat(absolutePath)).size,
      sha256: createHash("sha256").update(contents).digest("hex").slice(0, 16),
    })
  }
  await mkdir(evidenceDir, { recursive: true })
  await writeFile(
    path.join(evidenceDir, "bundle-manifest.json"),
    `${JSON.stringify({ build: pipeline.build, branch, commit, files: entries }, null, 2)}\n`,
  )
  return entries
}

async function ensureStaging() {
  if (stagingServer || ownsStagingServer) return "Local staging is already available"
  stagingServer = createDemoServer()
  try {
    await new Promise((resolve, reject) => {
      const handleError = (error) => reject(error)
      stagingServer.once("error", handleError)
      stagingServer.listen(stagingPort, stagingHost, () => {
        stagingServer.off("error", handleError)
        resolve()
      })
    })
    ownsStagingServer = true
    return `Started clean staging process on port ${stagingPort}`
  } catch (error) {
    stagingServer = undefined
    if (error.code !== "EADDRINUSE") throw error
    const response = await fetch(stagingUrl)
    const body = await response.text()
    if (!response.ok || !body.includes("<title>Engineering Project Management</title>")) {
      throw new Error(`Port ${stagingPort} is occupied by a different application`)
    }
    return `Reused healthy staging process on port ${stagingPort}`
  }
}

async function smokeStaging() {
  const checks = [
    ["frontend", "/", "GET", (body) => body.includes("Engineering Project Management")],
    ["login", "/prod-api/auth/login", "POST", (body) => JSON.parse(body).code === 200],
    ["dashboard", "/prod-api/project/statistics", "GET", (body) => JSON.parse(body).data.projectNum === 3],
    ["projects", "/prod-api/project/list", "POST", (body) => JSON.parse(body).data.total === 3],
    ["workflow", "/prod-api/workflow/process/todoList", "GET", (body) => JSON.parse(body).total === 2],
  ]
  for (const [name, route, method, validate] of checks) {
    const response = await fetch(`${stagingUrl}${route}`, { method })
    const body = await response.text()
    if (!response.ok || !validate(body)) throw new Error(`${name} smoke check failed`)
    log(`${name} ${route} -> HTTP ${response.status}`, "success")
  }
  return checks.length
}

async function writePipelineEvidence() {
  const evidence = {
    pipeline: pipeline.name,
    build: pipeline.build,
    status: pipeline.status,
    branch,
    commit,
    staging: { url: stagingUrl, scope: "localhost only", cloudServices: 0 },
    stages: pipeline.stages.map(({ id, name, status, detail }) => ({ id, name, status, detail })),
    generatedAt: new Date().toISOString(),
  }
  await mkdir(evidenceDir, { recursive: true })
  await writeFile(path.join(evidenceDir, "pipeline-evidence.json"), `${JSON.stringify(evidence, null, 2)}\n`)
}

async function runPipeline() {
  if (pipelineRunning) return
  pipelineRunning = true
  pipeline.status = "running"
  pipeline.startedAt = new Date().toISOString()
  pipeline.finishedAt = null
  pipeline.logs = []
  for (const item of pipeline.stages) Object.assign(item, { status: "queued", startedAt: null, finishedAt: null, detail: "Waiting" })

  try {
    log(`Build #${pipeline.build} started from ${branch}@${commit}`)
    await runStage("source", async (item) => {
      await execute(process.execPath, ["demo/ci/verify-delivery.mjs"])
      item.detail = "Tracked delivery contract verified"
    })
    await runStage("tests", async (item) => {
      await execute(process.execPath, ["--test", "demo/mock-server.test.mjs"])
      item.detail = "3 API suites passed"
    })
    await runStage("package", async (item) => {
      const entries = await createBundleManifest()
      item.detail = `${entries.length} artifact components fingerprinted`
    })
    await runStage("deploy", async (item) => {
      item.detail = await ensureStaging()
    })
    await runStage("smoke", async (item) => {
      item.detail = `${await smokeStaging()} live routes passed`
    })
    await runStage("release", async (item) => {
      const indexHtml = await readFile(path.join(projectRoot, "pmhub-ui/dist/index.html"), "utf8")
      if (!indexHtml.includes("Engineering Project Management")) throw new Error("Neutral application build is incomplete")
      item.detail = "Ready for Jun Kai to record"
    })
    pipeline.status = "passed"
    pipeline.finishedAt = new Date().toISOString()
    log("Local CI/CD pipeline passed. Staging remains available for recording.", "success")
  } catch (error) {
    const running = pipeline.stages.find((item) => item.status === "running")
    if (running) {
      running.status = "failed"
      running.finishedAt = new Date().toISOString()
      running.detail = error.message
    }
    pipeline.status = "failed"
    pipeline.finishedAt = new Date().toISOString()
    log(error.stack || error.message, "error")
  } finally {
    await writePipelineEvidence()
    pipelineRunning = false
  }
}

function sendJson(res, body, statusCode = 200) {
  const payload = JSON.stringify(body)
  res.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8", "Content-Length": Buffer.byteLength(payload), "Cache-Control": "no-store" })
  res.end(payload)
}

async function sendFile(res, filePath, contentType, downloadName) {
  const fileStat = await stat(filePath)
  const headers = { "Content-Type": contentType, "Content-Length": fileStat.size }
  if (downloadName) headers["Content-Disposition"] = `attachment; filename="${downloadName}"`
  res.writeHead(200, headers)
  createReadStream(filePath).pipe(res)
}

const dashboardServer = createServer(async (req, res) => {
  const url = new URL(req.url || "/", `http://${dashboardHost}:${dashboardPort}`)
  try {
    if (req.method === "GET" && url.pathname === "/") {
      await sendFile(res, dashboardPath, "text/html; charset=utf-8")
    } else if (req.method === "GET" && url.pathname === "/api/pipeline") {
      sendJson(res, pipeline)
    } else if (req.method === "POST" && url.pathname === "/api/run") {
      if (pipelineRunning) sendJson(res, { message: "Pipeline is already running" }, 409)
      else {
        pipeline.build += 1
        void runPipeline()
        sendJson(res, { message: `Build #${pipeline.build} started` }, 202)
      }
    } else if (req.method === "GET" && url.pathname === "/artifacts/bundle-manifest.json") {
      await sendFile(res, path.join(evidenceDir, "bundle-manifest.json"), "application/json; charset=utf-8", "bundle-manifest.json")
    } else if (req.method === "GET" && url.pathname === "/artifacts/pipeline-evidence.json") {
      await sendFile(res, path.join(evidenceDir, "pipeline-evidence.json"), "application/json; charset=utf-8", "pipeline-evidence.json")
    } else {
      sendJson(res, { message: "Not found" }, 404)
    }
  } catch (error) {
    sendJson(res, { message: error.message }, 500)
  }
})

dashboardServer.listen(dashboardPort, dashboardHost, () => {
  console.log(`Local Delivery Console: http://${dashboardHost}:${dashboardPort}`)
  console.log(`Interactive staging app: ${stagingUrl}`)
  setTimeout(() => void runPipeline(), 300)
})

function shutDown() {
  dashboardServer.close()
  if (ownsStagingServer) stagingServer?.close()
}

process.once("SIGINT", shutDown)
process.once("SIGTERM", shutDown)
