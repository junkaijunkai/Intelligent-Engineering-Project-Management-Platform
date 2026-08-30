#!/usr/bin/env bash
# 为 GitHub Pages 生成证据浏览首页：把下载合并后的证据目录渲染成可点击的文件树。
# 用法: generate-evidence-site.sh <site-dir>
set -euo pipefail

SITE_DIR="${1:?usage: generate-evidence-site.sh <site-dir>}"
INDEX="$SITE_DIR/index.html"
SHA="${GITHUB_SHA:-local}"
RUN_ID="${GITHUB_RUN_ID:-local}"

cat > "$INDEX" <<HEAD
<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="utf-8">
<title>DevSecOps CI Evidence</title>
<style>
  body { font-family: -apple-system, "Segoe UI", sans-serif; margin: 2rem; }
  ul { list-style: none; padding-left: 1.2rem; }
  li { margin: .2rem 0; }
  a { color: #0969da; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .dir { font-weight: 600; }
</style>
</head>
<body>
<h1>DevSecOps CI Evidence</h1>
<p>Commit: <code>$SHA</code> &middot; Run: <code>$RUN_ID</code></p>
<ul>
HEAD

find "$SITE_DIR" -mindepth 1 -maxdepth 6 ! -name index.html -print0 | sort -z | \
while IFS= read -r -d '' path; do
  rel="${path#"$SITE_DIR"/}"
  if [ -d "$path" ]; then
    printf '<li class="dir">%s/</li>\n' "$rel" >> "$INDEX"
  else
    printf '<li><a href="%s">%s</a></li>\n' "$rel" "$rel" >> "$INDEX"
  fi
done

cat >> "$INDEX" <<'TAIL'
</ul>
</body>
</html>
TAIL
