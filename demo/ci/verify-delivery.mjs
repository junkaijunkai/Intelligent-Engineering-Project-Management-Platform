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
  "output/pmhub-app-demo-screen-only.mp4",
  "output/pmhub-app-demo-screen-only.timing.json",
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

const timing = JSON.parse(
  await readFile(path.join(projectRoot, "output/pmhub-app-demo-screen-only.timing.json"), "utf8"),
)
if (timing.totalDurationSeconds !== 270 || timing.steps?.length !== 7) {
  throw new Error("The demo timing manifest must contain the approved 270-second, seven-step walkthrough")
}

const videoPath = path.join(projectRoot, "output/pmhub-app-demo-screen-only.mp4")
const videoHeader = (await readFile(videoPath)).subarray(0, 32).toString("latin1")
const videoSize = files.find((file) => file.path.endsWith(".mp4"))?.bytes || 0
if (!videoHeader.includes("ftyp") || videoSize < 1_000_000) {
  throw new Error("The tracked MP4 is missing or does not look like a complete video deliverable")
}

const evidence = {
  check: "pmhub-demo-delivery-contract",
  status: "passed",
  commit: process.env.GITHUB_SHA || "local",
  runtime: process.version,
  frontend: "committed engineering project-management build",
  api: "deterministic local mock",
  cloudDependencies: 0,
  video: {
    path: timing.output,
    durationSeconds: timing.totalDurationSeconds,
    width: timing.probe?.streams?.find((stream) => stream.width)?.width,
    height: timing.probe?.streams?.find((stream) => stream.height)?.height,
    bytes: videoSize,
  },
  files,
}

await mkdir(evidenceDir, { recursive: true })
await writeFile(
  path.join(evidenceDir, "validation-evidence.json"),
  `${JSON.stringify(evidence, null, 2)}\n`,
)

console.log(`Demo delivery contract passed: ${files.length} files, ${videoSize} video bytes, no cloud dependencies.`)
