#!/usr/bin/env python3
"""Small dependency-free IaC policy scanner for the local and CI environments."""
import html
import json
import os
import re
from pathlib import Path

ROOT = Path(os.environ["ROOT_DIR"])
OUT = Path(os.environ["OUT_DIR"]) / "04-compliance" / "iac"
MODE = os.environ.get("COMPLIANCE_MODE", os.environ.get("DEPLOY_ENV", "ci"))
POLICY = ROOT / "ci" / "config" / f"policy-{MODE}.json"

def finding(rule, severity, path, message, line=1):
    return {"rule": rule, "severity": severity, "path": str(path.relative_to(ROOT)), "line": line, "message": message}

def level(policy, rule):
    return policy["rules"].get(rule, "warning")

def line_number(text, needle):
    return text[: text.find(needle)].count("\n") + 1 if needle in text else 1

def main():
    policy = json.loads(POLICY.read_text(encoding="utf-8"))
    findings = []
    compose = ROOT / "docker" / "docker-compose.yml"
    text = compose.read_text(encoding="utf-8", errors="replace")

    for match in re.finditer(r"^\s*image:\s*([^\s#]+)", text, re.MULTILINE):
        image = match.group(1)
        if image == "latest" or image.endswith(":latest") or ":" not in image.split("@", 1)[0]:
            findings.append(finding("latest-image", level(policy, "latest-image"), compose,
                                    f"Image must use an explicit version or digest: {image}",
                                    text[: match.start()].count("\n") + 1))

    for match in re.finditer(r"^\s*privileged:\s*true\b", text, re.MULTILINE | re.IGNORECASE):
        findings.append(finding("privileged-container", level(policy, "privileged-container"), compose,
                                "Privileged containers are not allowed.", text[: match.start()].count("\n") + 1))

    for service in ("pmhub-mysql", "pmhub-redis"):
        block_match = re.search(rf"^  {re.escape(service)}:\n(?P<body>(?:^(?:    |\s*$).*(?:\n|$))*)", text, re.MULTILINE)
        body = block_match.group("body") if block_match else ""
        if re.search(r"^\s*-\s*['\"]?(?:33706:3306|6379:6379)", body, re.MULTILINE):
            findings.append(finding("public-data-port", level(policy, "public-data-port"), compose,
                                    f"{service} publishes a host port; CI should keep data services internal.",
                                    text[: block_match.start()].count("\n") + 1 if block_match else 1))

    core = ["pmhub-mysql", "pmhub-redis", "pmhub-nacos", "pmhub-gateway"]
    for service in core:
        block_match = re.search(rf"^  {re.escape(service)}:\n(?P<body>(?:^(?:    |\s*$).*(?:\n|$))*)", text, re.MULTILINE)
        body = block_match.group("body") if block_match else ""
        if "healthcheck:" not in body:
            findings.append(finding("missing-core-healthcheck", level(policy, "missing-core-healthcheck"), compose,
                                    f"Core service {service} must define a healthcheck."))

    for path in [ROOT / "docker" / "nacos" / "conf" / "application.properties", ROOT / "docker" / "seata" / "seata-application.yml"]:
        if not path.exists():
            continue
        for number, raw in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if re.search(r"(?:password|secret(?:Key)?|token)\s*[:=]", raw, re.IGNORECASE) and not re.search(r"\$\{|\benv\b|\bvalueFrom\b", raw, re.IGNORECASE):
                findings.append(finding("hardcoded-development-credential", level(policy, "hardcoded-development-credential"), path,
                                        "Known development credential is hardcoded; inject production values at runtime.", number))

    for path in [ROOT / "pmhub-gateway" / "docker" / "Dockerfile", ROOT / "pmhub-auth" / "docker" / "Dockerfile"]:
        if path.exists():
            docker_text = path.read_text(encoding="utf-8", errors="replace")
            if not re.search(r"^USER\s+", docker_text, re.MULTILINE):
                findings.append(finding("root-container", level(policy, "root-container"), path,
                                        "Dockerfile does not declare a non-root USER."))

    OUT.mkdir(parents=True, exist_ok=True)
    errors = [x for x in findings if x["severity"] == "error"]
    warnings = [x for x in findings if x["severity"] == "warning"]
    result = {"mode": MODE, "policy": str(POLICY.relative_to(ROOT)), "status": "FAIL" if errors else "PASS", "errors": len(errors), "warnings": len(warnings), "findings": findings}
    (OUT / "policy-results.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    (OUT / "policy-results.html").write_text("<html><body><h1>IaC Compliance</h1><p>Mode: " + html.escape(MODE) + "</p><table><tr><th>Severity</th><th>Rule</th><th>Location</th><th>Message</th></tr>" + "".join(f"<tr><td>{html.escape(x['severity'])}</td><td>{html.escape(x['rule'])}</td><td>{html.escape(x['path'])}:{x['line']}</td><td>{html.escape(x['message'])}</td></tr>" for x in findings) + "</table></body></html>\n", encoding="utf-8")
    (OUT / "policy-results.txt").write_text("Mode: " + MODE + "\nStatus: " + result["status"] + "\n" + "\n".join(f"{x['severity'].upper()} {x['rule']} {x['path']}:{x['line']} - {x['message']}" for x in findings) + "\n", encoding="utf-8")
    sarif = {"version": "2.1.0", "runs": [{"tool": {"driver": {"name": "pvision-iac-policy"}}, "results": [{"ruleId": x["rule"], "level": "error" if x["severity"] == "error" else "warning", "message": {"text": x["message"]}, "locations": [{"physicalLocation": {"artifactLocation": {"uri": x["path"]}, "region": {"startLine": x["line"]}}}]} for x in findings]}]}
    (OUT / "policy-results.sarif").write_text(json.dumps(sarif, indent=2) + "\n", encoding="utf-8")
    print((OUT / "policy-results.txt").read_text(encoding="utf-8"), end="")
    if errors:
        raise SystemExit(1)

if __name__ == "__main__":
    main()
