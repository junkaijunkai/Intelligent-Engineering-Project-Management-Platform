import assert from "node:assert/strict"
import { after, before, test } from "node:test"

import { createDemoServer } from "./mock-server.mjs"

let server
let baseUrl

before(async () => {
  server = createDemoServer()
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve))
  baseUrl = `http://127.0.0.1:${server.address().port}`
})

after(async () => {
  await new Promise((resolve, reject) => server.close((error) => (error ? reject(error) : resolve())))
})

test("serves the real PmHub frontend build", async () => {
  const response = await fetch(baseUrl)
  assert.equal(response.status, 200)
  assert.match(await response.text(), /<title>PmHub<\/title>/)
})

test("supports the login and dynamic-route bootstrap", async () => {
  const login = await fetch(`${baseUrl}/prod-api/auth/login`, { method: "POST" }).then((response) => response.json())
  assert.equal(login.code, 200)
  assert.equal(login.token, "pmhub-local-demo-token")

  const info = await fetch(`${baseUrl}/prod-api/system/user/getInfo`).then((response) => response.json())
  assert.deepEqual(info.roles, ["admin"])

  const routerResult = await fetch(`${baseUrl}/prod-api/system/menu/getRouters`).then((response) => response.json())
  assert.equal(routerResult.data.length, 2)
})

test("returns stable project, task, and workflow demo evidence", async () => {
  const statistics = await fetch(`${baseUrl}/prod-api/project/statistics`).then((response) => response.json())
  assert.equal(statistics.data.projectNum, 3)
  assert.equal(statistics.data.taskNum, 18)

  const projectResult = await fetch(`${baseUrl}/prod-api/project/list`, { method: "POST" }).then((response) => response.json())
  assert.equal(projectResult.data.list[0].projectCode, "IEPM-2026-001")

  const taskResult = await fetch(`${baseUrl}/prod-api/project/task/list`, { method: "POST" }).then((response) => response.json())
  assert.equal(taskResult.data.total, 4)

  const filteredProjects = await fetch(`${baseUrl}/prod-api/project/list`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ status: 2 }),
  }).then((response) => response.json())
  assert.deepEqual(filteredProjects.data.list.map((project) => project.projectCode), ["IEPM-2026-003"])

  const filteredTasks = await fetch(`${baseUrl}/prod-api/project/task/list`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ projectId: 102 }),
  }).then((response) => response.json())
  assert.deepEqual(filteredTasks.data.list.map((task) => task.taskId), [5004])

  const workflowResult = await fetch(`${baseUrl}/prod-api/workflow/process/todoList`).then((response) => response.json())
  assert.equal(workflowResult.total, 2)
})
