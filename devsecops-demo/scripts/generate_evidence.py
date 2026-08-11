#!/usr/bin/env python3
"""Build self-contained, screenshot-ready evidence pages from local reports."""

from __future__ import annotations

import html
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

DEMO = Path(__file__).resolve().parents[1]
OUT = DEMO / "out"
PRESENTATION = OUT / "06-presentation"
PAGES = PRESENTATION / "pages"


def read_json(relative: str, default=None):
    try:
        return json.loads((OUT / relative).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {} if default is None else default


def read_text(relative: str, default="Not available"):
    try:
        value = (OUT / relative).read_text(encoding="utf-8", errors="replace").strip()
        return value or default
    except OSError:
        return default


def esc(value):
    return html.escape(str(value))


def status(stage: str):
    data = read_json(f"00-metadata/status/{stage}.json")
    return data.get("status", "NOT RUN")


def badge(value: str):
    key = str(value).upper()
    css = "pass" if key in {"PASS", "PASSED", "OK", "DEMONSTRATED"} else "warn" if key in {"NOT RUN", "OPTIONAL", "SKIP", "PARTIAL", "OUT OF SCOPE"} else "fail"
    return f'<span class="badge {css}">{esc(value)}</span>'


def severity_counts(items):
    counts = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0, "INFO": 0}
    for severity in items:
        key = str(severity or "INFO").upper()
        counts[key if key in counts else "INFO"] += 1
    return counts


def semgrep_counts():
    report = read_json("03-security/sast/semgrep.json")
    severities = [x.get("extra", {}).get("severity", "INFO") for x in report.get("results", [])]
    return severity_counts(severities)


def trivy_counts(relative):
    report = read_json(relative)
    severities = []
    for result in report.get("Results") or []:
        severities.extend(x.get("Severity", "INFO") for x in (result.get("Vulnerabilities") or []))
        severities.extend(x.get("Severity", "INFO") for x in (result.get("Misconfigurations") or []))
    return severity_counts(severities)


def zap_counts():
    report = read_json("03-security/dast/zap-report.json")
    counts = {"HIGH": 0, "MEDIUM": 0, "LOW": 0, "INFO": 0}
    for site in report.get("site", []):
        for alert in site.get("alerts", []):
            risk = str(alert.get("riskdesc", "Informational")).split()[0].upper()
            key = "INFO" if risk.startswith("INFO") else risk
            counts[key if key in counts else "INFO"] += 1
    return counts


def metric_card(label, value, note=""):
    return f'<div class="metric"><div class="metric-value">{esc(value)}</div><div class="metric-label">{esc(label)}</div><div class="metric-note">{esc(note)}</div></div>'


def bars(counts):
    colors = {"CRITICAL": "#9b1c31", "HIGH": "#df2935", "MEDIUM": "#f59e0b", "LOW": "#1d70b8", "INFO": "#718096"}
    maximum = max([1] + list(counts.values()))
    result = ['<div class="bars">']
    for name in ("CRITICAL", "HIGH", "MEDIUM", "LOW", "INFO"):
        if name not in counts:
            continue
        width = max(2, round(counts[name] / maximum * 100)) if counts[name] else 0
        result.append(f'<div class="bar-row"><span>{name}</span><div class="bar-track"><div class="bar-fill" style="width:{width}%;background:{colors[name]}"></div></div><strong>{counts[name]}</strong></div>')
    result.append("</div>")
    return "".join(result)


CSS = """
*{box-sizing:border-box}body{margin:0;background:#e8edf5;color:#14213d;font-family:Arial,Helvetica,sans-serif} .slide{width:1200px;height:900px;background:#f7f9fc;overflow:hidden;position:relative;padding:54px 62px} .topline{height:10px;background:#153f7d;position:absolute;left:0;right:0;top:0}.eyebrow{font-size:16px;letter-spacing:2px;text-transform:uppercase;color:#1d70b8;font-weight:700}.title{font-size:42px;line-height:1.08;margin:8px 0 12px;color:#183f78}.subtitle{font-size:20px;color:#52647a;margin-bottom:28px}.grid{display:grid;grid-template-columns:repeat(12,1fr);gap:18px}.card{background:#fff;border:1px solid #d7deea;border-radius:12px;padding:22px;box-shadow:0 4px 14px rgba(24,63,120,.07)}.card h2{font-size:22px;margin:0 0 14px;color:#183f78}.card h3{font-size:17px;margin:0 0 10px;color:#52647a}.metric{background:#eef3fa;border-left:5px solid #1d70b8;border-radius:7px;padding:15px;min-height:112px}.metric-value{font-size:31px;font-weight:700;color:#183f78}.metric-label{font-size:15px;font-weight:700;margin-top:5px}.metric-note{font-size:12px;color:#697a90;margin-top:4px}.metrics{display:grid;grid-template-columns:repeat(4,1fr);gap:14px}.bullets{margin:0;padding-left:22px;font-size:19px;line-height:1.55}.bullets li{margin:7px 0}.badge{display:inline-block;border-radius:999px;padding:5px 11px;font-size:13px;font-weight:700}.pass{background:#d9f2e6;color:#146c43}.warn{background:#fff0c2;color:#8a5a00}.fail{background:#fde0e3;color:#9b1c31}.bars{display:grid;gap:10px}.bar-row{display:grid;grid-template-columns:78px 1fr 35px;align-items:center;gap:10px;font-size:13px}.bar-track{height:15px;background:#e7ebf1;border-radius:8px;overflow:hidden}.bar-fill{height:100%;border-radius:8px}.flow{display:flex;align-items:center;justify-content:space-between;gap:8px}.node{flex:1;text-align:center;background:#eaf1fa;border:1px solid #b8c9df;border-radius:9px;padding:17px 8px;font-weight:700;color:#183f78}.arrow{font-size:25px;color:#1d70b8}.code{background:#17243a;color:#dce8f8;border-radius:8px;padding:14px;font:13px/1.45 Menlo,monospace;white-space:pre-wrap}.table{width:100%;border-collapse:collapse;font-size:15px}.table th,.table td{padding:10px 12px;border-bottom:1px solid #dce3ed;text-align:left}.table th{background:#eaf1fa;color:#183f78}.footer{position:absolute;bottom:20px;left:62px;right:62px;display:flex;justify-content:space-between;color:#6e7d91;font-size:12px}.span4{grid-column:span 4}.span5{grid-column:span 5}.span6{grid-column:span 6}.span7{grid-column:span 7}.span8{grid-column:span 8}.span12{grid-column:span 12}.small{font-size:14px;color:#63748a}.dashboard{width:1440px;min-height:1200px;height:auto;padding-bottom:90px}.dashboard .title{font-size:46px}
html,body{overflow:hidden}
"""


def page(title, subtitle, body, source, dashboard=False):
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    cls = "slide dashboard" if dashboard else "slide"
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><style>{CSS}</style></head><body><main class="{cls}"><div class="topline"></div><div class="eyebrow">Pvision DevSecOps Evidence</div><div class="title">{esc(title)}</div><div class="subtitle">{esc(subtitle)}</div>{body}<div class="footer"><span>Generated from local result artifacts · {esc(source)}</span><span>{stamp}</span></div></main></body></html>'''


def write(relative, content):
    path = OUT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def compliance():
    git_lines = read_text("04-compliance/git/git-audit-trail.txt", "").splitlines()
    mapping = [
        ("Art. 5 — Security & accountability", "Git history, pipeline evidence, immutable reports", "Demonstrated"),
        ("Art. 25 — Data protection by design", "SAST, DAST, image and IaC scanning", "Demonstrated"),
        ("Art. 30 — Records of processing", "Version-controlled audit trail", "Partial"),
        ("Art. 32 — Security of processing", "Testing, vulnerability management, container controls", "Demonstrated"),
        ("Art. 33 — Breach notification", "Operational policy and incident workflow", "Out of scope"),
    ]
    rows = "".join(f"<tr><td>{esc(a)}</td><td>{esc(e)}</td><td>{badge(s)}</td></tr>" for a, e, s in mapping)
    body = f'''<div class="grid"><section class="card span12"><h2>GDPR evidence mapping</h2><table class="table"><thead><tr><th>Control theme</th><th>Project evidence</th><th>Demo status</th></tr></thead><tbody>{rows}</tbody></table></section><section class="card span12"><ul class="bullets"><li>Assessment mapping only — not a certification.</li><li>Evidence is scoped to source, pipeline, and demo containers.</li><li>{len(git_lines)} recent commits retained as an audit trail.</li></ul></section></div>'''
    write("04-compliance/gdpr/gdpr-assessment-mapping.html", page("GDPR Assessment Mapping", "A bounded regulatory framework demonstration", body, "Git, tests, scans, container evidence"))
    write("04-compliance/gdpr/gdpr-assessment-mapping.json", json.dumps({"framework": "GDPR", "disclaimer": "Assessment mapping only; not certification.", "controls": [{"control": a, "evidence": e, "status": s} for a, e, s in mapping]}, indent=2))

    sem = semgrep_counts(); image = trivy_counts("03-security/image/trivy-frontend.json"); zap = zap_counts()
    remediation = read_text("05-vulnerability/remediation-history.txt", "No matching historical commit found.")
    body = f'''<div class="grid"><section class="card span7"><h2>Current rescan results</h2>{bars({"HIGH":sem["HIGH"]+image["HIGH"]+zap["HIGH"],"MEDIUM":sem["MEDIUM"]+image["MEDIUM"]+zap["MEDIUM"],"LOW":sem["LOW"]+image["LOW"]+zap["LOW"],"INFO":sem["INFO"]+image["INFO"]+zap["INFO"]})}</section><section class="card span5"><h2>Resolution loop</h2><div class="flow"><div class="node">Find</div><div class="arrow">›</div><div class="node">Fix</div><div class="arrow">›</div><div class="node">Rescan</div></div><ul class="bullets"><li>Findings remain visible.</li><li>Reports are regenerated.</li><li>History records remediation.</li></ul></section><section class="card span12"><h2>Security-related history</h2><div class="code">{esc(remediation[:1600])}</div></section></div>'''
    write("05-vulnerability/remediation-and-rescan.html", page("Vulnerability Assessment", "Resolution history and current rescan evidence", body, "Semgrep, Trivy, ZAP, Git"))
    write("05-vulnerability/remediation-and-rescan.json", json.dumps({"semgrep": sem, "trivyImage": image, "zap": zap, "historyEntries": len(remediation.splitlines())}, indent=2))


def generate_pages():
    unit = read_json("01-testing/unit/unit-test-summary.json")
    integration = read_json("01-testing/integration/integration-summary.json")
    k6 = read_json("01-testing/load/k6-summary.json")
    km = k6.get("metrics", {})
    p95 = km.get("http_req_duration", {}).get("values", {}).get("p(95)", "N/A")
    reqs = km.get("http_reqs", {}).get("values", {}).get("count", "N/A")
    failrate = km.get("http_req_failed", {}).get("values", {}).get("rate")
    failrate = f"{failrate*100:.2f}%" if isinstance(failrate, (int, float)) else "N/A"
    tools = read_json("00-metadata/toolchain.json")
    flow = '<div class="flow">' + '<div class="node">' + '</div><div class="arrow">›</div><div class="node">'.join(["Unit", "Container", "Integration", "Load", "SAST", "Trivy", "DAST", "Evidence"]) + '</div></div>'
    body = f'''<div class="grid"><section class="card span12"><h2>Sequential, manually triggered pipeline</h2>{flow}</section><section class="card span12"><div class="metrics">{metric_card("Unit tests", unit.get("tests","N/A"), f'{unit.get("failures","?")} failures')}{metric_card("Line coverage", f'{unit.get("lineCoveragePercent","N/A")}%','Result artifact')}{metric_card("Integration", integration.get("status","N/A"), f'{integration.get("assertions","?")} assertions')}{metric_card("k6 requests", reqs, f'p95 {p95} ms')}</div></section><section class="card span12"><ul class="bullets"><li>One workflow · one sequential job · one evidence artifact</li><li>JUnit, JaCoCo, integration, and k6 result artifacts retained</li><li>Security findings stay visible without hiding report generation</li></ul></section></div>'''
    write("06-presentation/pages/01-cicd-evidence.html", page("CI/CD & Testing Evidence", "GitHub Actions workflow_dispatch · sequential execution", body, "JUnit, JaCoCo, k6, workflow YAML"))

    inspect = read_json("02-container/frontend-image-inspect.json", [{}])
    image_size = inspect[0].get("Size", 0) if isinstance(inspect, list) and inspect else 0
    image_mb = f"{image_size/1024/1024:.1f} MB" if image_size else "N/A"
    image = trivy_counts("03-security/image/trivy-frontend.json")
    body = f'''<div class="grid"><section class="card span7"><h2>Container lifecycle</h2><div class="flow"><div class="node">Build</div><div class="arrow">›</div><div class="node">Run</div><div class="arrow">›</div><div class="node">Inspect</div><div class="arrow">›</div><div class="node">Logs</div></div><div class="metrics" style="margin-top:18px;grid-template-columns:repeat(3,1fr)">{metric_card("Image", "Nginx", tools.get("NGINX_IMAGE","Pinned"))}{metric_card("Image size", image_mb, "Docker inspect")}{metric_card("Health", status("frontend"), "/health")}</div></section><section class="card span5"><h2>Trivy image findings</h2>{bars(image)}</section><section class="card span12"><ul class="bullets"><li>Image build and runtime metadata exported as JSON.</li><li>Container health and logs captured as evidence.</li><li>Trivy scans the exact demo image.</li></ul></section></div>'''
    write("06-presentation/pages/02-container-management.html", page("Container Management", "Build, run, inspect, log, and scan", body, "Docker inspect, logs, Trivy"))

    sem = semgrep_counts(); zap = zap_counts(); image = trivy_counts("03-security/image/trivy-frontend.json")
    body = f'''<div class="grid"><section class="card span4"><h2>Semgrep · SAST</h2>{bars(sem)}</section><section class="card span4"><h2>Trivy · Image</h2>{bars(image)}</section><section class="card span4"><h2>ZAP · DAST</h2>{bars(zap)}</section><section class="card span12"><div class="flow"><div class="node">Detect</div><div class="arrow">›</div><div class="node">Prioritize</div><div class="arrow">›</div><div class="node">Remediate</div><div class="arrow">›</div><div class="node">Rescan</div></div></section><section class="card span12"><ul class="bullets"><li>Machine-readable JSON/SARIF plus human-readable HTML.</li><li>Historical security commits demonstrate the resolution trail.</li><li>Findings are evidence; missing reports fail validation.</li></ul></section></div>'''
    write("06-presentation/pages/03-vulnerability-assessment.html", page("Vulnerability Assessment", "SAST, image security, DAST, and rescan evidence", body, "Semgrep, Trivy, ZAP, Git"))

    iac = trivy_counts("04-compliance/iac/trivy-iac.json")
    git_count = len(read_text("04-compliance/git/git-audit-trail.txt", "").splitlines())
    body = f'''<div class="grid"><section class="card span6"><h2>Infrastructure as Code</h2>{bars(iac)}<div style="margin-top:18px">{badge(status("trivy"))}</div></section><section class="card span6"><h2>Version control audit trail</h2>{metric_card("Recent commits", git_count, "Hash · timestamp · author · subject")}<div class="code" style="margin-top:14px">{esc(read_text("04-compliance/git/git-audit-trail.txt", "Not available")[:600])}</div></section><section class="card span12"><ul class="bullets"><li>Dockerfiles and configuration are scanned as code.</li><li>Git history provides traceable change evidence.</li><li>Tool versions and execution environment are recorded.</li></ul></section></div>'''
    write("06-presentation/pages/04-compliance-as-code.html", page("Compliance as Code", "Repeatable controls, machine-readable reports, auditable changes", body, "Trivy IaC, Git, toolchain metadata"))

    body = '''<div class="grid"><section class="card span12"><h2>GDPR control-to-evidence map</h2><table class="table"><thead><tr><th>GDPR theme</th><th>Evidence shown</th><th>Scope</th></tr></thead><tbody><tr><td>Art. 5 · Accountability</td><td>Pipeline artifacts and Git audit trail</td><td>Demonstrated</td></tr><tr><td>Art. 25 · Protection by design</td><td>SAST, DAST, image and IaC scans</td><td>Demonstrated</td></tr><tr><td>Art. 30 · Processing records</td><td>Version-controlled history</td><td>Partial</td></tr><tr><td>Art. 32 · Security of processing</td><td>Testing and vulnerability management</td><td>Demonstrated</td></tr></tbody></table></section><section class="card span12"><ul class="bullets"><li>Assessment mapping only — not GDPR certification.</li><li>Technical evidence supports selected security obligations.</li><li>Legal, policy, and operational controls remain outside demo scope.</li></ul></section></div>'''
    write("06-presentation/pages/05-regulatory-framework.html", page("Regulatory Framework · GDPR", "Evidence mapping with explicit scope and limitations", body, "GDPR mapping, project evidence"))

    statuses = ["unit-tests", "frontend", "integration", "load", "sast", "trivy", "dast", "compliance"]
    cards = "".join(metric_card(x.replace("-", " ").title(), status(x), "Evidence stage") for x in statuses)
    body = f'''<div class="grid"><section class="card span12"><h2>Execution status</h2><div class="metrics">{cards}</div></section><section class="card span6"><h2>Testing</h2><ul class="bullets"><li>{esc(unit.get("tests","N/A"))} unit tests</li><li>{esc(unit.get("lineCoveragePercent","N/A"))}% line coverage</li><li>Integration: {esc(integration.get("status","N/A"))}</li><li>k6 requests: {esc(reqs)}</li></ul></section><section class="card span6"><h2>Security & compliance</h2><ul class="bullets"><li>Semgrep SAST</li><li>Trivy image and IaC</li><li>ZAP baseline DAST</li><li>Git audit trail and GDPR map</li></ul></section></div>'''
    write("06-presentation/dashboard.html", page("DevSecOps Evidence Dashboard", "A single review surface for the assessment demo", body, "All generated result artifacts", dashboard=True))


def real_evidence_pages():
    raw = PRESENTATION / "raw-screenshots"

    def shot(name, label, position="top"):
        uri = (raw / name).resolve().as_uri()
        return f'<figure class="evidence-shot"><img src="{uri}" style="object-position:{position}"><figcaption>{esc(label)}</figcaption></figure>'

    evidence_css = '''<style>
      .evidence-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}
      .evidence-grid.three{grid-template-columns:repeat(3,1fr)}
      .evidence-shot{margin:0;background:#fff;border:1px solid #cfd8e5;padding:8px;border-radius:8px;overflow:hidden}
      .evidence-shot img{width:100%;height:455px;object-fit:cover;display:block;border:1px solid #e1e6ee}
      .evidence-grid.three .evidence-shot img{height:420px}
      .evidence-shot figcaption{font-size:14px;font-weight:700;color:#183f78;padding:8px 3px 2px}
      .evidence-note{font-size:16px;margin-top:14px;color:#40536b}
    </style>'''

    body = evidence_css + '<div class="evidence-grid three">' + \
        shot("01-unit-maven-result.png", "Maven / Surefire · BUILD SUCCESS") + \
        shot("02-unit-jacoco-report.png", "JaCoCo · Native HTML report") + \
        shot("04-load-k6-result.png", "k6 · VUs, checks, and thresholds") + \
        '</div><div class="evidence-note">JUnit XML and integration smoke artifacts are retained in the same evidence package.</div>'
    write("06-presentation/pages/01-cicd-evidence.html", page("CI/CD & Testing Evidence", "Real local reports · add the GitHub Actions run screenshot after manual execution", body, "Maven, Surefire, JaCoCo, k6"))

    body = evidence_css + '<div class="evidence-grid">' + \
        shot("05-container-runtime-result.png", "Docker · container ID, image, health, and logs") + \
        shot("07-image-trivy-result.png", "Trivy · vulnerabilities for the exact demo image") + \
        '</div><div class="evidence-note">Image build, inspect JSON, runtime logs, and the complete Trivy report are retained.</div>'
    write("06-presentation/pages/02-container-management.html", page("Container Management", "Runtime and image-security evidence from the local Docker execution", body, "Docker runtime, Trivy image scan"))

    body = evidence_css + '<div class="evidence-grid">' + \
        shot("06-sast-semgrep-result.png", "Semgrep SAST · files, rules, and findings") + \
        shot("08-dast-zap-report.png", "OWASP ZAP DAST · target, version, and alerts") + \
        '</div><div class="evidence-note">JSON, SARIF, HTML, and console artifacts support drill-down and rescanning.</div>'
    write("06-presentation/pages/03-vulnerability-assessment.html", page("Vulnerability Assessment", "Real SAST and DAST reports with retained finding details", body, "Semgrep, OWASP ZAP"))

    body = evidence_css + '<div class="evidence-grid">' + \
        shot("10-iac-trivy-result.png", "Trivy IaC · scanned Dockerfiles and concrete rule failures") + \
        shot("11-git-audit-trail.png", "Git · hash, timestamp, author, and change subject") + \
        '</div><div class="evidence-note">Controls are reproducible from versioned code and machine-readable artifacts.</div>'
    write("06-presentation/pages/04-compliance-as-code.html", page("Compliance as Code", "IaC scan output and version-control audit evidence", body, "Trivy configuration scan, Git history"))

    body = evidence_css + '<div class="evidence-grid">' + \
        shot("12-gdpr-evidence-map.png", "GDPR assessment map · bounded technical scope") + \
        shot("13-remediation-rescan.png", "Evidence links · current scans and security-related history") + \
        '</div><div class="evidence-note">Assessment mapping only — not certification; legal and operational controls remain out of scope.</div>'
    write("06-presentation/pages/05-regulatory-framework.html", page("Regulatory Framework · GDPR", "Each demonstrated control points to retained technical evidence", body, "GDPR evidence map, Semgrep, Trivy, ZAP, Git"))


def main():
    PAGES.mkdir(parents=True, exist_ok=True)
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    if mode in {"all", "compliance"}:
        compliance()
    if mode in {"all", "dashboard"}:
        generate_pages()
    if mode in {"all", "real-slides"}:
        real_evidence_pages()


if __name__ == "__main__":
    main()
