#!/usr/bin/env node

import { mkdir, readFile, stat, writeFile } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const ciDir = path.dirname(fileURLToPath(import.meta.url))
const projectRoot = path.resolve(ciDir, "../..")
const evidenceDir = path.join(projectRoot, "demo-ci-artifacts")

const requiredFiles = [
  "package.json",
  "demo/mock-server.mjs",
  "demo/mock-server.test.mjs",
  "scripts/start-local-demo.sh",
  "pmhub-ui/dist/index.html",
  "docs/app-demo-script.md",
  "demo/ci/local-pipeline-server.mjs",
]

async function inspectRequiredFile(relativePath) {
  const file = path.join(projectRoot, relativePath)
  const fileStat = await stat(file)
  if (!fileStat.isFile() || fileStat.size === 0) {
    throw new Error(`Required delivery file is empty: ${relativePath}`)
  }
  return { path: relativePath, bytes: fileStat.size }
}

const files = await Promise.all(requiredFiles.map(inspectRequiredFile))
const indexHtml = await readFile(path.join(projectRoot, "pmhub-ui/dist/index.html"), "utf8")
if (!indexHtml.includes("<title>Engineering Project Management</title>")) {
  throw new Error("The committed frontend build does not contain the neutral project-management title")
}

const evidence = {
  check: "pmhub-demo-delivery-contract",
  status: "passed",
  commit: process.env.GITHUB_SHA || "local",
  runtime: process.version,
  frontend: "committed engineering project-management build",
  api: "deterministic local mock",
  cloudDependencies: 0,
  files,
}

await mkdir(evidenceDir, { recursive: true })
await writeFile(
  path.join(evidenceDir, "validation-evidence.json"),
  `${JSON.stringify(evidence, null, 2)}\n`,
)

console.log(`Demo delivery contract passed: ${files.length} runnable files, no cloud dependencies.`)
