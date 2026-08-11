#!/usr/bin/env node

import { readFile, writeFile } from "node:fs/promises"
import path from "node:path"
import { fileURLToPath } from "node:url"

const brandingDir = path.dirname(fileURLToPath(import.meta.url))
const projectRoot = path.resolve(brandingDir, "../..")
const distRoot = path.join(projectRoot, "pmhub-ui", "dist")

async function replaceInFile(relativePath, replacements) {
  const filePath = path.join(distRoot, relativePath)
  let content = await readFile(filePath, "utf8")
  let changed = false

  for (const [search, replacement] of replacements) {
    if (content.includes(search)) {
      content = content.split(search).join(replacement)
      changed = true
    }
  }

  if (changed) await writeFile(filePath, content)
  return changed
}

await replaceInFile("index.html", [
  ["<link rel=icon href=/favicon.png>", ""],
  ["<title>PmHub</title>", "<title>Engineering Project Management</title>"],
  ['+".js?v=neutral-20260811"}', '+".js?v=neutral-20260811b"}'],
  ['+".js"}', '+".js?v=neutral-20260811b"}'],
  [
    "<script src=/static/js/app.7b0d4c3d.js?v=neutral-20260811></script>",
    "<script src=/static/js/app.7b0d4c3d.js?v=neutral-20260811b></script>",
  ],
  [
    "<script src=/static/js/app.7b0d4c3d.js></script>",
    "<script src=/static/js/app.7b0d4c3d.js?v=neutral-20260811b></script>",
  ],
])

const bundles = [
  "static/js/app.7b0d4c3d.js",
  "static/js/chunk-27fa32f0.0fda90e5.js",
  "static/js/chunk-47844143.978446d3.js",
  "static/js/chunk-7fcd6520.648a9860.js",
]

for (const bundle of bundles) {
  await replaceInFile(bundle, [
    ["PmHub", "Engineering Project Management"],
    ["sidebarLogo:!0", "sidebarLogo:!1"],
    ["showLogo:function(){return this.$store.state.settings.sidebarLogo}", "showLogo:function(){return!1}"],
    [
      't("img",{staticClass:"user-avatar",attrs:{src:e.avatar}})',
      't("span",{staticClass:"user-avatar",staticStyle:{display:"inline-flex","align-items":"center","justify-content":"center",background:"#2563eb",color:"#fff","font-size":"13px","font-weight":"700"}},[e._v("JK")])',
    ],
    [
      't("span",[e._v("Copyright © 2022-至今 ")]),t("a",{attrs:{href:"https://github.com/laigeoffer",target:"_blank"}},[e._v("来个offer官方，")]),t("a",{attrs:{href:"https://github.com/laigeoffer/pmhub",target:"_blank"}},[e._v("项目源码")])',
      't("span",[e._v("Engineering Project Management Demo")])',
    ],
    ["Copyright © 2018-2022 ruoyi.vip All Rights Reserved.", "Engineering Project Management Demo"],
  ])
}

const visibleFiles = ["index.html", ...bundles]
for (const relativePath of visibleFiles) {
  const content = await readFile(path.join(distRoot, relativePath), "utf8")
  if (content.includes("PmHub")) throw new Error(`Legacy visible brand remains in ${relativePath}`)
}

console.log("Neutral application branding applied to the committed frontend build.")
