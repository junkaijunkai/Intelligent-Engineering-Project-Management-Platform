#!/usr/bin/env bash
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

# Remove local absolute paths and common credential-bearing URL forms from text artifacts.
while IFS= read -r -d '' file; do
  FILE_TO_SANITIZE="$file" python3 - <<'PY'
import os, re
from pathlib import Path
p = Path(os.environ["FILE_TO_SANITIZE"])
try:
    text = p.read_text(encoding="utf-8")
except UnicodeDecodeError:
    raise SystemExit(0)
except OSError as exc:
    print(f"[sanitize-artifacts] skip unreadable file: {p} ({exc})")
    raise SystemExit(0)
root = os.environ["ROOT_DIR"]
text = text.replace(root, "<workspace>")
text = re.sub(r'(?i)(https?://)[^/@\s:]+:[^/@\s]+@', r'\1<redacted>@', text)
text = re.sub(r'(?i)(authorization["\s:=]+(?:bearer\s+)?)[A-Za-z0-9._~+/=-]{12,}', r'\1<redacted>', text)
try:
    p.write_text(text, encoding="utf-8")
except OSError as exc:
    print(f"[sanitize-artifacts] skip unwritable file: {p} ({exc})")
PY
done < <(find "$OUT_DIR" -type f \( -name '*.txt' -o -name '*.log' -o -name '*.json' -o -name '*.xml' -o -name '*.html' -o -name '*.md' -o -name '*.sarif' \) -print0)

if rg --no-messages -n --hidden -i '(BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|github_pat_[A-Za-z0-9_]{20,}|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16})' "$OUT_DIR"; then
  record_status sanitization FAILED "Potential secret material remains in evidence."
  exit 1
fi
record_status sanitization PASS "Local paths and common credential patterns were sanitized."
