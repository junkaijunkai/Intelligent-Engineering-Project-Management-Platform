#!/usr/bin/env node

import { execFileSync } from "node:child_process"
import { existsSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs"
import os from "node:os"
import path from "node:path"
import { fileURLToPath } from "node:url"

const recordingDir = path.dirname(fileURLToPath(import.meta.url))
const projectRoot = path.resolve(recordingDir, "../..")

function parseArguments(argv) {
  const options = {
    assetsDir: path.join(recordingDir, "assets"),
    configPath: path.join(recordingDir, "motion-config.json"),
    outputPath: path.join(projectRoot, "output", "pmhub-app-demo-screen-only.mp4"),
  }

  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index]
    if (argument === "--assets") options.assetsDir = path.resolve(argv[++index])
    else if (argument === "--config") options.configPath = path.resolve(argv[++index])
    else if (argument === "--output") options.outputPath = path.resolve(argv[++index])
    else if (argument === "--help" || argument === "-h") {
      console.log("Usage: node demo/recording/render-demo.mjs [--assets DIR] [--config FILE] [--output FILE]")
      process.exit(0)
    } else throw new Error(`Unknown argument: ${argument}`)
  }
  return options
}

function run(command, args, capture = false) {
  return execFileSync(command, args, {
    encoding: capture ? "utf8" : undefined,
    stdio: capture ? ["ignore", "pipe", "pipe"] : "inherit",
  })
}

function escapeConcatPath(file) {
  return file.replaceAll("'", "'\\''")
}

function probe(file, entries) {
  return run("ffprobe", [
    "-v", "error",
    "-show_entries", entries,
    "-of", "json",
    file,
  ], true)
}

function humanMotionExpression(points, coordinateIndex, timeExpression) {
  let expression = String(points.at(-1)[coordinateIndex])
  for (let index = points.length - 2; index >= 0; index -= 1) {
    const current = points[index]
    const next = points[index + 1]
    const duration = next[0] - current[0]
    if (duration <= 0) continue
    const start = current[coordinateIndex]
    const end = next[coordinateIndex]
    const distance = Math.hypot(next[1] - current[1], next[2] - current[2])
    const bend = (index % 2 === 0 ? 1 : -1) * Math.min(20, distance * 0.05)
    const dx = next[1] - current[1]
    const dy = next[2] - current[2]
    const perpendicular = distance > 0 ? (coordinateIndex === 1 ? -dy / distance : dx / distance) : 0
    const unitTime = `((${timeExpression})-${current[0]})/${duration}`
    const eased = `(3*pow(${unitTime},2)-2*pow(${unitTime},3))`
    const arc = `${(perpendicular * bend).toFixed(6)}*sin(PI*${unitTime})`
    const interpolation = `${start}+(${end}-${start})*${eased}+${arc}`
    expression = `if(lt(${timeExpression},${next[0]}),${interpolation},${expression})`
  }
  return expression
}

function smoothKeyframeExpression(keyframes, coordinateIndex, timeExpression) {
  let expression = String(keyframes.at(-1)[coordinateIndex])
  for (let index = keyframes.length - 2; index >= 0; index -= 1) {
    const current = keyframes[index]
    const next = keyframes[index + 1]
    const duration = next[0] - current[0]
    if (duration <= 0) continue
    const start = current[coordinateIndex]
    const end = next[coordinateIndex]
    const unitTime = `((${timeExpression})-${current[0]})/${duration}`
    const eased = `(3*pow(${unitTime},2)-2*pow(${unitTime},3))`
    expression = `if(lt(${timeExpression},${next[0]}),${start}+(${end}-${start})*${eased},${expression})`
  }
  return expression
}

function deduplicateKeyframes(keyframes) {
  const result = []
  for (const frame of [...keyframes].sort((left, right) => left[0] - right[0])) {
    if (result.length && Math.abs(result.at(-1)[0] - frame[0]) < 0.000001) result[result.length - 1] = frame
    else result.push(frame)
  }
  return result
}

function cameraKeyframes(step, config) {
  const { clickZoom, holdSeconds, releaseSeconds } = config.motion
  const duration = step.durationSeconds
  const center = [config.canvas.outputWidth / 2, config.canvas.outputHeight / 2]
  const scaleX = config.canvas.outputWidth / config.canvas.width
  const scaleY = config.canvas.outputHeight / config.canvas.height
  const frames = []

  if (step.incomingClick) {
    const [x, y] = step.incomingClick
    frames.push(
      [0, clickZoom, x * scaleX, y * scaleY],
      [holdSeconds, clickZoom, x * scaleX, y * scaleY],
      [holdSeconds + releaseSeconds, 1, x * scaleX, y * scaleY],
    )
  } else frames.push([0, 1, ...center])

  if (step.exitClick) {
    const [x, y] = step.exitClick.focus
    frames.push(
      [Math.max(0, step.exitClick.at - 0.55), 1, x * scaleX, y * scaleY],
      [Math.min(duration, step.exitClick.at + 0.15), clickZoom, x * scaleX, y * scaleY],
      [duration, clickZoom, x * scaleX, y * scaleY],
    )
  } else frames.push([duration, 1, ...center])

  return deduplicateKeyframes(frames)
}

function renderSegment(step, config, assetsDir, cursorPath, outputPath) {
  const imagePath = path.join(assetsDir, step.asset)
  if (!existsSync(imagePath)) throw new Error(`Missing screenshot: ${imagePath}`)

  const cursorX = humanMotionExpression(step.cursor, 1, "t")
  const cursorY = humanMotionExpression(step.cursor, 2, "t")
  const camera = cameraKeyframes(step, config)
  const cameraTime = "on/30"
  const zoom = smoothKeyframeExpression(camera, 1, cameraTime)
  const focusX = smoothKeyframeExpression(camera, 2, cameraTime)
  const focusY = smoothKeyframeExpression(camera, 3, cameraTime)
  const { width, height, outputWidth, outputHeight, fps } = config.canvas

  const filter = [
    `[0:v]scale=${width}:${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2:white,setsar=1,format=rgba[background]`,
    "[1:v]format=rgba[cursor]",
    `[background][cursor]overlay=x='${cursorX}':y='${cursorY}':eval=frame:shortest=1[pointed]`,
    `[pointed]scale=${outputWidth}:${outputHeight},setsar=1[canvas]`,
    `[canvas]zoompan=z='${zoom}':x='min(max(${focusX}-iw/zoom/2,0),iw-iw/zoom)':y='min(max(${focusY}-ih/zoom/2,0),ih-ih/zoom)':d=1:s=${outputWidth}x${outputHeight}:fps=${fps},format=yuv420p[out]`,
  ].join(";")

  console.log(`Rendering ${step.id}: ${step.durationSeconds}s — ${step.title}`)
  run("ffmpeg", [
    "-hide_banner", "-loglevel", "error", "-y",
    "-loop", "1", "-framerate", String(fps), "-i", imagePath,
    "-loop", "1", "-framerate", String(fps), "-i", cursorPath,
    "-filter_complex", filter,
    "-map", "[out]", "-t", String(step.durationSeconds),
    "-an", "-c:v", "libx264", "-preset", "veryfast", "-crf", "18", "-r", String(fps),
    outputPath,
  ])
}

const options = parseArguments(process.argv.slice(2))
const config = JSON.parse(readFileSync(options.configPath, "utf8"))
const cursorPath = path.join(options.assetsDir, "cursor.png")
if (!existsSync(cursorPath)) throw new Error(`Missing cursor asset: ${cursorPath}`)

const workDir = mkdtempSync(path.join(os.tmpdir(), "pmhub-demo-render-"))
const segmentDir = path.join(workDir, "segments")
mkdirSync(segmentDir, { recursive: true })
mkdirSync(path.dirname(options.outputPath), { recursive: true })

const segments = []
for (const [index, step] of config.steps.entries()) {
  const output = path.join(segmentDir, `${String(index + 1).padStart(2, "0")}-${step.id}.mp4`)
  renderSegment(step, config, options.assetsDir, cursorPath, output)
  segments.push(output)
}

const concatPath = path.join(workDir, "segments.txt")
writeFileSync(concatPath, segments.map((file) => `file '${escapeConcatPath(file)}'`).join("\n"))
const videoOnlyPath = path.join(workDir, "pmhub-app-demo-video.mp4")
run("ffmpeg", [
  "-hide_banner", "-loglevel", "error", "-y",
  "-f", "concat", "-safe", "0", "-i", concatPath,
  "-c", "copy", "-movflags", "+faststart", videoOnlyPath,
])

const totalDuration = config.steps.reduce((sum, step) => sum + step.durationSeconds, 0)
run("ffmpeg", [
  "-hide_banner", "-loglevel", "error", "-y",
  "-i", videoOnlyPath,
  "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
  "-map", "0:v:0", "-map", "1:a:0", "-t", String(totalDuration),
  "-c:v", "copy", "-c:a", "aac", "-b:a", "128k", "-shortest", "-movflags", "+faststart",
  options.outputPath,
])

const timingPath = options.outputPath.replace(/\.mp4$/i, ".timing.json")
const timing = {
  title: config.title,
  totalDurationSeconds: totalDuration,
  output: path.relative(projectRoot, options.outputPath),
  probe: JSON.parse(probe(options.outputPath, "format=duration,size:stream=codec_name,width,height,r_frame_rate")),
  steps: config.steps.map(({ id, title, asset, durationSeconds }) => ({ id, title, asset, durationSeconds })),
}
writeFileSync(timingPath, `${JSON.stringify(timing, null, 2)}\n`)
console.log(JSON.stringify(timing, null, 2))
