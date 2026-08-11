import { createReadStream } from "node:fs"
import { access, stat } from "node:fs/promises"
import { createServer } from "node:http"
import path from "node:path"
import { fileURLToPath } from "node:url"

const demoDir = path.dirname(fileURLToPath(import.meta.url))
const projectRoot = path.resolve(demoDir, "..")
const distRoot = path.join(projectRoot, "pmhub-ui", "dist")

const projects = [
  {
    projectId: 101,
    projectCode: "IEPM-2026-001",
    projectName: "Smart Campus Delivery Platform",
    stageName: "Integration & Validation",
    statusName: "进行中",
    projectTypeName: "私有项目",
    publishedName: "已发布",
    projectProcess: 78,
    process: 78,
    nickName: "Jun Kai",
    closeEndTime: "2026-08-28 18:00:00",
    collected: true,
    cover: "/demo/cover-campus.svg",
  },
  {
    projectId: 102,
    projectCode: "IEPM-2026-002",
    projectName: "AI Risk Forecasting Pilot",
    stageName: "User Acceptance Test",
    statusName: "进行中",
    projectTypeName: "公开项目",
    publishedName: "已发布",
    projectProcess: 64,
    process: 64,
    nickName: "Jun Kai",
    closeEndTime: "2026-09-12 18:00:00",
    collected: false,
    cover: "/demo/cover-ai.svg",
  },
  {
    projectId: 103,
    projectCode: "IEPM-2026-003",
    projectName: "Contractor Handover Workflow",
    stageName: "Delivery & Handover",
    statusName: "已归档",
    projectTypeName: "私有项目",
    publishedName: "已发布",
    projectProcess: 100,
    process: 100,
    nickName: "Alicia Tan",
    closeEndTime: "2026-07-31 18:00:00",
    collected: true,
    cover: "/demo/cover-handover.svg",
  },
]

const tasks = [
  {
    taskId: 5001,
    taskName: "Validate schedule-risk prediction",
    projectId: 101,
    projectName: projects[0].projectName,
    stageName: "Integration & Validation",
    executor: "Jun Kai",
    executeStatusName: "进行中",
    statusName: "进行中",
    taskPriorityName: "最高",
    createdBy: "Alicia Tan",
    period: 5,
    closeTime: "2026-08-15 18:00:00",
    createdTime: "2026-08-08 09:30:00",
    taskProcess: 72,
  },
  {
    taskId: 5002,
    taskName: "Review BIM issue escalation workflow",
    projectId: 101,
    projectName: projects[0].projectName,
    stageName: "Integration & Validation",
    executor: "Wei Ming",
    executeStatusName: "进行中",
    statusName: "进行中",
    taskPriorityName: "较高",
    createdBy: "Jun Kai",
    period: 3,
    closeTime: "2026-08-17 18:00:00",
    createdTime: "2026-08-09 14:15:00",
    taskProcess: 55,
  },
  {
    taskId: 5003,
    taskName: "Prepare sponsor acceptance evidence",
    projectId: 101,
    projectName: projects[0].projectName,
    stageName: "Delivery & Handover",
    executor: "Jun Kai",
    executeStatusName: "未开始",
    statusName: "未开始",
    taskPriorityName: "普通",
    createdBy: "Alicia Tan",
    period: 4,
    closeTime: "2026-08-22 18:00:00",
    createdTime: "2026-08-10 10:00:00",
    taskProcess: 0,
  },
  {
    taskId: 5004,
    taskName: "Close API integration defects",
    projectId: 102,
    projectName: projects[1].projectName,
    stageName: "User Acceptance Test",
    executor: "Siti Nur",
    executeStatusName: "已完成",
    statusName: "已完成",
    taskPriorityName: "较高",
    createdBy: "Jun Kai",
    period: 7,
    closeTime: "2026-08-10 18:00:00",
    createdTime: "2026-08-01 11:00:00",
    taskProcess: 100,
  },
]

const routes = [
  {
    hidden: false,
    name: "Pmhub-project",
    path: "/pmhub-project",
    component: "Layout",
    alwaysShow: true,
    redirect: "noRedirect",
    meta: { title: "项目管理", icon: "project", noCache: false },
    children: [
      {
        hidden: false,
        name: "My-project",
        path: "my-project",
        component: "pmhub-project/my-project",
        meta: { title: "我的项目", icon: "list", noCache: false },
      },
      {
        hidden: false,
        name: "My-task",
        path: "my-task",
        component: "pmhub-project/my-task",
        meta: { title: "我的任务", icon: "checkbox", noCache: false },
      },
    ],
  },
  {
    hidden: false,
    name: "Work",
    path: "/work",
    component: "Layout",
    alwaysShow: true,
    redirect: "noRedirect",
    meta: { title: "我的事务", icon: "job", noCache: false },
    children: [
      {
        hidden: false,
        name: "Todo",
        path: "todo",
        component: "workflow/work/todo",
        meta: { title: "待办任务", icon: "time-range", noCache: true },
      },
      {
        hidden: false,
        name: "Finished",
        path: "finished",
        component: "workflow/work/finished",
        meta: { title: "已办任务", icon: "checkbox", noCache: true },
      },
    ],
  },
]

const todoRows = [
  {
    taskId: "WF-TASK-301",
    procInsId: "WF-2026-0811-01",
    procDefId: "project-approval:3:301",
    deployId: "DEPLOY-301",
    procDefName: "Project Gate Approval",
    taskName: "Sponsor acceptance review",
    procDefVersion: 3,
    startUserName: "Jun Kai",
    startDeptName: "Digital Delivery",
    createTime: "2026-08-11 09:20:00",
    duration: "2h 16m",
    suspendState: 1,
  },
  {
    taskId: "WF-TASK-302",
    procInsId: "WF-2026-0810-04",
    procDefId: "risk-exception:2:302",
    deployId: "DEPLOY-302",
    procDefName: "Risk Exception Review",
    taskName: "Project manager assessment",
    procDefVersion: 2,
    startUserName: "Wei Ming",
    startDeptName: "Engineering",
    createTime: "2026-08-10 15:45:00",
    duration: "19h 51m",
    suspendState: 1,
  },
]

const finishedRows = [
  {
    taskId: "WF-TASK-289",
    procInsId: "WF-2026-0808-02",
    procDefId: "task-change:5:289",
    deployId: "DEPLOY-289",
    procDefName: "Task Change Control",
    taskName: "Delivery lead approval",
    startUserName: "Siti Nur",
    startDeptName: "Project Controls",
    createTime: "2026-08-08 11:10:00",
    finishTime: "2026-08-08 16:42:00",
    duration: "5h 32m",
  },
  {
    taskId: "WF-TASK-276",
    procInsId: "WF-2026-0806-01",
    procDefId: "project-approval:3:276",
    deployId: "DEPLOY-276",
    procDefName: "Project Gate Approval",
    taskName: "Technical review",
    startUserName: "Jun Kai",
    startDeptName: "Digital Delivery",
    createTime: "2026-08-06 09:00:00",
    finishTime: "2026-08-07 14:20:00",
    duration: "1d 5h",
  },
]

const json = (res, payload, statusCode = 200) => {
  const body = JSON.stringify(payload)
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(body),
    "Cache-Control": "no-store",
  })
  res.end(body)
}

const ok = (data = null, extra = {}) => ({ code: 200, msg: "操作成功", data, ...extra })

function apiResponse(pathname, method, requestBody = {}) {
  if (pathname === "/prod-api/auth/login" && method === "POST") {
    return { code: 200, msg: "登录成功", token: "pmhub-local-demo-token" }
  }
  if (pathname === "/prod-api/auth/logout") return ok()
  if (pathname === "/prod-api/system/user/getInfo") {
    return {
      code: 200,
      user: { userId: 1, userName: "Jun Kai", nickName: "Jun Kai", avatar: "" },
      roles: ["admin"],
      permissions: ["*:*:*"],
    }
  }
  if (pathname === "/prod-api/system/menu/getRouters") return ok(routes)
  if (pathname === "/prod-api/project/statistics") {
    return ok({
      projectNum: projects.length,
      taskNum: 18,
      todayTaskNum: 4,
      overdueTaskNum: 1,
      projectRankVOList: projects.map((project) => ({
        projectName: project.projectName,
        process: project.projectProcess,
      })),
      taskStatisticsVOList: [
        { statusName: "进行中", taskNum: 8 },
        { statusName: "已完成", taskNum: 6 },
        { statusName: "未开始", taskNum: 3 },
        { statusName: "已逾期", taskNum: 1 },
      ],
    })
  }
  if (pathname === "/prod-api/project/doing") return ok(projects.filter((project) => project.statusName === "进行中"))
  if (pathname === "/prod-api/project/select" || pathname === "/prod-api/project/queryAllProject") {
    return ok(projects.map(({ projectId, projectName, statusName }) => ({ projectId, projectName, statusName })))
  }
  if (pathname === "/prod-api/project/queryMyTaskList") {
    const filteredTasks = requestBody.projectId
      ? tasks.filter((task) => task.projectId === Number(requestBody.projectId))
      : tasks
    return ok({ total: filteredTasks.length, list: filteredTasks })
  }
  if (pathname === "/prod-api/project/list") {
    const statusNames = { 0: "未开始", 1: "进行中", 2: "已归档", 3: "已逾期", 4: "已暂停" }
    const keyword = String(requestBody.keyword || "").trim().toLowerCase()
    const filteredProjects = projects.filter((project) => {
      const matchesStatus = requestBody.status === undefined || requestBody.status === null
        || project.statusName === statusNames[requestBody.status]
      const matchesKeyword = !keyword
        || project.projectName.toLowerCase().includes(keyword)
        || project.projectCode.toLowerCase().includes(keyword)
      return matchesStatus && matchesKeyword
    })
    return ok({ total: filteredProjects.length, list: filteredProjects })
  }
  if (pathname === "/prod-api/project/task/list") {
    const keyword = String(requestBody.taskName || "").trim().toLowerCase()
    const filteredTasks = tasks.filter((task) => {
      const matchesProject = !requestBody.projectId || task.projectId === Number(requestBody.projectId)
      const matchesKeyword = !keyword || task.taskName.toLowerCase().includes(keyword)
      return matchesProject && matchesKeyword
    })
    return ok({ total: filteredTasks.length, list: filteredTasks })
  }
  if (pathname === "/prod-api/project/stage/list") {
    return ok([
      { stageId: 1, stageCode: 1, stageName: "Planning" },
      { stageId: 2, stageCode: 2, stageName: "Implementation" },
      { stageId: 3, stageCode: 3, stageName: "Integration & Validation" },
      { stageId: 4, stageCode: 4, stageName: "Delivery & Handover" },
    ])
  }
  if (pathname === "/prod-api/workflow/process/todoList") {
    return { code: 200, msg: "查询成功", rows: todoRows, total: todoRows.length }
  }
  if (pathname === "/prod-api/workflow/process/finishedList") {
    return { code: 200, msg: "查询成功", rows: finishedRows, total: finishedRows.length }
  }
  if (pathname === "/prod-api/workflow/task/complete") return ok(null, { msg: "审批已完成（本地演示）" })
  if (pathname.startsWith("/prod-api/")) return ok([])
  return null
}

const mimeTypes = {
  ".css": "text/css; charset=utf-8",
  ".gif": "image/gif",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
}

async function serveStatic(res, pathname) {
  const requested = pathname === "/" ? "/index.html" : pathname
  const safeRelativePath = path.normalize(decodeURIComponent(requested)).replace(/^[/\\]+/, "")
  let filePath = path.resolve(distRoot, safeRelativePath)

  if (!filePath.startsWith(distRoot + path.sep)) {
    json(res, { code: 403, msg: "Forbidden" }, 403)
    return
  }

  try {
    await access(filePath)
    if (!(await stat(filePath)).isFile()) throw new Error("not a file")
  } catch {
    filePath = path.join(distRoot, "index.html")
  }

  const fileStat = await stat(filePath)
  res.writeHead(200, {
    "Content-Type": mimeTypes[path.extname(filePath).toLowerCase()] || "application/octet-stream",
    "Content-Length": fileStat.size,
    "Cache-Control": filePath.endsWith("index.html") ? "no-store" : "public, max-age=3600",
  })
  createReadStream(filePath).pipe(res)
}

export function createDemoServer() {
  return createServer(async (req, res) => {
    const url = new URL(req.url || "/", "http://127.0.0.1")

    if (url.pathname.startsWith("/prod-api/demo/cover-")) {
      const palette = url.pathname.includes("ai") ? ["#6D5DFB", "#55D6BE"] : ["#1677FF", "#39A0ED"]
      const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="180" height="120"><defs><linearGradient id="g" x2="1" y2="1"><stop stop-color="${palette[0]}"/><stop offset="1" stop-color="${palette[1]}"/></linearGradient></defs><rect width="180" height="120" rx="14" fill="url(#g)"/><path d="M24 86l34-42 24 27 23-19 49 34" fill="none" stroke="white" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" opacity=".92"/></svg>`
      res.writeHead(200, { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=3600" })
      res.end(svg)
      return
    }

    let requestBody = {}
    if (["POST", "PUT", "PATCH", "DELETE"].includes(req.method || "")) {
      const chunks = []
      for await (const chunk of req) chunks.push(chunk)
      const rawBody = Buffer.concat(chunks).toString("utf8")
      if (rawBody) {
        try {
          requestBody = JSON.parse(rawBody)
        } catch {
          requestBody = Object.fromEntries(new URLSearchParams(rawBody))
        }
      }
    }

    const payload = apiResponse(url.pathname, req.method || "GET", requestBody)
    if (payload) {
      json(res, payload)
      return
    }

    try {
      await serveStatic(res, url.pathname)
    } catch (error) {
      json(res, { code: 500, msg: error.message }, 500)
    }
  })
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const port = Number(process.env.PORT || 4173)
  const host = process.env.HOST || "127.0.0.1"
  const server = createDemoServer()
  server.listen(port, host, () => {
    console.log(`PmHub local demo is ready: http://${host}:${port}`)
    console.log("Demo login: any username and password")
    console.log("All API responses use deterministic in-memory data; no cloud services are contacted.")
  })
}
