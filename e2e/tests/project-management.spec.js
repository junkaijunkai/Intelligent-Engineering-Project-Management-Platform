const { test, expect } = require('@playwright/test')

const menus = [
  {
    path: '/pmhub-project',
    component: 'Layout',
    redirect: 'noRedirect',
    name: 'ProjectManagement',
    alwaysShow: true,
    meta: { title: '项目管理', icon: 'tab' },
    children: [
      {
        path: 'my-project',
        component: 'pmhub-project/my-project',
        name: 'MyProject',
        meta: { title: '我的项目', icon: 'list' },
      },
      {
        path: 'my-task',
        component: 'pmhub-project/my-task',
        name: 'MyTask',
        meta: { title: '我的任务', icon: 'task' },
      },
    ],
  },
]

const initialProjects = [
  {
    projectId: 'project-001',
    projectCode: 'E2E-001',
    projectName: '智能巡检平台',
    stageName: '研发实施阶段',
    statusName: '进行中',
    projectTypeName: '公开项目',
    publishedName: '已发布',
    projectProcess: 60,
    nickName: '演示管理员',
    closeEndTime: '2026-12-31 18:00:00',
    collected: false,
  },
]

function ok(data) {
  return { status: 200, contentType: 'application/json', body: JSON.stringify({ code: 200, data }) }
}

async function installApiMock(page) {
  const projects = initialProjects.map((project) => ({ ...project }))
  const tasks = [{ taskId: 'task-001', taskName: '完成现场验收', projectName: '智能巡检平台', stageName: '研发实施阶段', executor: '演示成员', executeStatusName: '进行中', statusName: '进行中', taskPriorityName: '普通', createdBy: '演示管理员', period: 3, closeTime: '2026-12-31 18:00:00', taskProcess: 50 }]
  let authenticated = false

  // Vue's development proxy removes the /dev-api prefix before the browser
  // request is observed, so intercept the actual service paths instead.
  await page.route(/\/(auth|system|project)\//, async (route) => {
    const request = route.request()
    const url = new URL(request.url())
    const path = url.pathname.replace('/dev-api', '')
    const body = request.postDataJSON ? request.postDataJSON() : undefined

    if (path === '/auth/login') {
      authenticated = true
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({ code: 200, token: 'e2e-demo-token' }),
      })
    }
    if (path === '/system/user/getInfo') {
      // The legacy guard calls next() twice on public routes after GetInfo
      // resolves. Keep this unauthenticated request pending so /login stays
      // on the login page; authenticated requests still resolve immediately.
      if (!authenticated) {
        await new Promise((resolve) => setTimeout(resolve, 10_000))
      }
      return route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          code: 200,
          user: { userName: 'E2E 演示管理员', avatar: '' },
          roles: ['admin'],
          permissions: ['*:*:*'],
        }),
      })
    }
    if (path === '/system/menu/getRouters') return route.fulfill(ok(menus))
    if (path === '/project/statistics') return route.fulfill(ok({ projectNum: 1, taskNum: 2, todayTaskNum: 1, overdueTaskNum: 0, projectRankVOList: [], taskStatisticsVOList: [] }))
    if (path === '/project/doing') return route.fulfill(ok([{ projectName: '智能巡检平台', nickName: '演示管理员', process: 60, cover: '' }]))
    if (path === '/project/select') return route.fulfill(ok(initialProjects))
    if (path === '/project/queryMyTaskList') return route.fulfill(ok({ total: 1, list: [{ taskId: 'task-001', taskName: '完成现场验收', statusName: '进行中' }] }))
    if (path === '/project/task/list') {
      const list = tasks.filter((task) => !body.taskName || task.taskName.includes(body.taskName))
      return route.fulfill(ok({ total: list.length, list }))
    }
    if (path === '/project/task/queryExecutorList') return route.fulfill(ok([{ userId: 'user-001', nickName: '演示成员' }]))
    if (path === '/project/stage/list') return route.fulfill(ok([{ stageId: 'stage-001', stageCode: 1, stageName: '研发实施阶段' }]))
    if (path === '/project/task/add') {
      tasks.unshift({ taskId: `task-${tasks.length + 1}`, taskName: body.taskName, projectName: '智能巡检平台', stageName: '研发实施阶段', executor: '演示成员', executeStatusName: '未开始', statusName: '未开始', taskPriorityName: '普通', createdBy: '演示管理员', period: 0, closeTime: '', taskProcess: 0 })
      return route.fulfill(ok(null))
    }
    if (path === '/project/list') {
      const keyword = body && body.keyword ? body.keyword : ''
      const list = projects.filter((project) => project.projectName.includes(keyword))
      return route.fulfill(ok({ total: list.length, list }))
    }
    if (path === '/project/add') {
      projects.unshift({
        projectId: `project-${projects.length + 1}`,
        projectCode: 'E2E-NEW',
        projectName: body.projectName,
        stageName: '项目立项阶段',
        statusName: '未开始',
        projectTypeName: body.type === 1 ? '私有项目' : '公开项目',
        publishedName: '未发布',
        projectProcess: 0,
        nickName: 'E2E 演示管理员',
        closeEndTime: body.closeEndTime || '',
        collected: false,
      })
      return route.fulfill(ok(null))
    }
    if (path === '/project/collect' || path === '/project/cancelCollect') {
      const project = projects.find((item) => item.projectId === body.projectId)
      if (project) project.collected = path === '/project/collect'
      return route.fulfill(ok(null))
    }
    return route.fulfill(ok({ total: 0, list: [] }))
  })
}

async function login(page, waitForMenu = false) {
  await page.goto('/login', { waitUntil: 'domcontentloaded' })
  await page.getByPlaceholder('账号').fill('admin')
  await page.getByPlaceholder('密码').fill('admin123')

  const loginResponse = page.waitForResponse((response) => response.url().includes('/auth/login') && response.status() === 200)
  const menuResponse = waitForMenu
    ? page.waitForResponse((response) => response.url().includes('/system/menu/getRouters') && response.status() === 200)
    : null
  await page.locator('.login-form .el-button--primary').click()
  await loginResponse
  if (menuResponse) await menuResponse
}

async function openProjectMenu(page, target) {
  const targetPath = target === 'projects' ? '/pmhub-project/my-project' : '/pmhub-project/my-task'
  await login(page, true)
  await page.goto(targetPath, { waitUntil: 'domcontentloaded' })
  await expect(page).toHaveURL(new RegExp(`${targetPath}$`))
}

async function openProjectList(page) {
  await openProjectMenu(page, 'projects')
  await expect(page.getByRole('button', { name: '新建项目' })).toBeVisible()
}

async function openTaskList(page) {
  await openProjectMenu(page, 'tasks')
  await expect(page.getByRole('button', { name: '新建任务' })).toBeVisible()
}

async function selectTaskDialogOption(page, dialog, fieldLabel, option) {
  const field = dialog.locator('.el-form-item').filter({ hasText: fieldLabel })
  await field.locator('.el-select').click()
  await page.locator('.el-select-dropdown:visible').getByText(option, { exact: true }).click()
}

test.beforeEach(async ({ page }) => {
  // A fresh browser context can still open on the dev server's current SPA document.
  // Leave that document before changing authentication state so Vue is booted anew.
  await page.goto('about:blank')
  await page.context().clearCookies()
  await installApiMock(page)
})

test('登录页阻止空凭据提交', async ({ page }) => {
  await page.goto('/login')
  await page.locator('.login-form .el-button--primary').click()
  await expect(page.getByText('请输入账号')).toBeVisible()
  await expect(page.getByText('请输入密码')).toBeVisible()
})

test('登录后展示项目统计和进行中项目', async ({ page }) => {
  await login(page)
  await expect(page.getByText('项目名:智能巡检平台', { exact: true })).toBeVisible()
  await expect(page.getByText('60%')).toBeVisible()
})

test('登录后展示我的任务', async ({ page }) => {
  await login(page)
  await expect(page.getByText('完成现场验收')).toBeVisible()
  await expect(page.getByText('进行中', { exact: true })).toBeVisible()
})

test('项目查询、新建并收藏', async ({ page }) => {
  await openProjectList(page)
  const searchInput = page.getByPlaceholder('请输入项目名或编码')
  await searchInput.fill('巡检')
  await page.locator('.search-wrapper .el-button--primary').click()
  await expect(page.getByText('智能巡检平台', { exact: true })).toBeVisible()
  await page.getByRole('button', { name: '新建项目' }).click()
  const dialog = page.locator('.el-dialog__wrapper:visible')
  await dialog.getByPlaceholder('请输入').first().fill('E2E 项目演示')
  await dialog.locator('.el-dialog__footer .el-button--primary').click()
  await expect(page.getByRole('alert').filter({ hasText: '创建成功' })).toBeVisible()
  await searchInput.fill('')
  await page.locator('.search-wrapper .el-button--primary').click()
  const row = page.locator('.el-table__body-wrapper tr').filter({ hasText: 'E2E 项目演示' })
  await row.locator('.el-button--text').last().click()
  await expect(page.getByRole('alert').filter({ hasText: '收藏成功' })).toBeVisible()
  await expect(row.locator('.el-button--text').last()).toBeVisible()
})

test('新建任务并按任务名筛选', async ({ page }) => {
  await openTaskList(page)
  await page.getByRole('button', { name: '新建任务' }).click()
  const dialog = page.locator('.el-dialog__wrapper:visible')
  await dialog.getByPlaceholder('请输入').first().fill('E2E 任务演示')
  await selectTaskDialogOption(page, dialog, '所属项目', '智能巡检平台')
  await selectTaskDialogOption(page, dialog, '优先级', '普通')
  await selectTaskDialogOption(page, dialog, '执行人', '演示成员')
  await dialog.locator('.el-dialog__footer .el-button--primary').click()
  await expect(page.locator('.el-message--success')).toBeVisible()
  await page.locator('.search-wrapper input[placeholder="请输入"]').first().fill('E2E 任务演示')
  await page.locator('.search-wrapper .el-button--primary').click()
  await expect(page.getByText('E2E 任务演示')).toBeVisible()
})
