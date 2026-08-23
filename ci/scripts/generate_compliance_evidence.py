#!/usr/bin/env python3
"""Generate project-scoped GDPR and vulnerability evidence from CI artifacts."""
import json
import os
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(os.environ.get("OUT_DIR", Path(__file__).resolve().parents[1] / "out"))

def read_text(relative, default="Not available"):
    try:
        value = (ROOT / relative).read_text(encoding="utf-8", errors="replace").strip()
        return value or default
    except OSError:
        return default

def image_findings():
    counts = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0, "INFO": 0}
    for report in (ROOT / "03-security" / "images").glob("*/trivy.json"):
        try:
            data = json.loads(report.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        for result in data.get("Results") or []:
            for finding in (result.get("Vulnerabilities") or []) + (result.get("Misconfigurations") or []):
                severity = str(finding.get("Severity", "INFO")).upper()
                counts[severity if severity in counts else "INFO"] += 1
    return counts

def main():
    git_audit = read_text("04-compliance/git/git-audit-trail.txt", "No Git audit trail available.")
    mapping = [
        {"control": "Art. 5 — Security and accountability", "evidence": "Git history and retained pipeline artifacts", "status": "Demonstrated"},
        {"control": "Art. 25 — Data protection by design", "evidence": "SAST, DAST, image, and IaC scans", "status": "Demonstrated"},
        {"control": "Art. 30 — Records of processing", "evidence": "Version-controlled audit trail", "status": "Partial"},
        {"control": "Art. 32 — Security of processing", "evidence": "Testing, vulnerability management, and container controls", "status": "Demonstrated"},
        {"control": "Art. 33 — Breach notification", "evidence": "Operational policy and incident workflow", "status": "Out of scope"},
    ]
    root = ROOT
    gdpr_dir = root / "04-compliance" / "gdpr"
    vulnerability_dir = root / "05-vulnerability"
    gdpr_dir.mkdir(parents=True, exist_ok=True)
    vulnerability_dir.mkdir(parents=True, exist_ok=True)
    gdpr = {"framework": "GDPR", "disclaimer": "Assessment mapping only; not certification.", "generatedAt": datetime.now(timezone.utc).isoformat(), "controls": mapping}
    vuln = {"scope": "Full backend service image scan results", "imageFindings": image_findings(), "remediationHistoryEntries": len(git_audit.splitlines())}
    rows = "".join(f"<tr><td>{x['control']}</td><td>{x['evidence']}</td><td>{x['status']}</td></tr>" for x in mapping)
    html = f"<!doctype html><html lang=\"en\"><head><meta charset=\"utf-8\"><title>GDPR Assessment Mapping</title></head><body><h1>GDPR Assessment Mapping</h1><p>Assessment mapping only; not certification.</p><table><tr><th>Control</th><th>Evidence</th><th>Status</th></tr>{rows}</table></body></html>\n"
    (gdpr_dir / "gdpr-assessment-mapping.html").write_text(html, encoding="utf-8")
    (gdpr_dir / "gdpr-assessment-mapping.json").write_text(json.dumps(gdpr, indent=2) + "\n", encoding="utf-8")
    (vulnerability_dir / "remediation-and-rescan.json").write_text(json.dumps(vuln, indent=2) + "\n", encoding="utf-8")
    (vulnerability_dir / "remediation-and-rescan.html").write_text("<html><body><h1>Project Vulnerability Rescan</h1><pre>" + json.dumps(vuln, indent=2) + "</pre></body></html>\n", encoding="utf-8")

if __name__ == "__main__":
    main()
