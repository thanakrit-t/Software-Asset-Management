from pathlib import Path
import json
import sys

REQUIRED_FILES = [
    "README.md",
    "policy/global-baseline.json",
    "policy/project-policy.example.json",
    "templates/root-AGENTS.md",
    "templates/module-AGENTS.md",
    "templates/task.md",
    "templates/checkpoint.md",
    "templates/risk-assessment.md",
    "templates/change-standard.md",
    "templates/change-enterprise.md",
    "templates/evidence-lightweight.md",
    "templates/evidence-standard.md",
    "templates/evidence-enterprise.md",
    "prompts/master-operating-prompt.md",
    "prompts/session-start.md",
    "prompts/session-end.md",
    "docs/rollout-checklist.md",
    "docs/verification-plan.md",
]

ROOT_AGENT_HEADINGS = [
    "# Project Purpose",
    "# Global Architecture",
    "# ACPW Governance",
    "# Context Loading Rules",
    "# Security Baseline",
    "# Verification Commands",
    "# Definition of Done",
]


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def validate_global_policy(policy: dict) -> list[str]:
    errors: list[str] = []
    if policy.get("governance_order") != ["Lightweight", "Standard", "Enterprise"]:
        errors.append("governance_order must be Lightweight, Standard, Enterprise")
    expected_weights = {
        "security": 25,
        "data_production": 25,
        "blast_radius": 20,
        "reversibility": 15,
        "business_operational_impact": 10,
        "complexity": 5,
    }
    weights = policy.get("risk_weights", {})
    if sum(weights.values()) != 100:
        errors.append("risk_weights must sum to 100")
    if weights != expected_weights:
        errors.append("risk_weights must match ACPW v1.0")
    expected_thresholds = {
        "Lightweight": [0, 29],
        "Standard": [30, 64],
        "Enterprise": [65, 100],
    }
    if policy.get("thresholds") != expected_thresholds:
        errors.append("thresholds must match ACPW v1.0")
    for name, level in policy.get("hard_rules", {}).items():
        if level not in {"Standard", "Enterprise"}:
            errors.append(f"hard rule {name} has invalid minimum {level}")
    if policy.get("full_repository_scan_default") is not False:
        errors.append("full_repository_scan_default must be false")
    return errors


def validate_project_policy(global_policy: dict, project_policy: dict) -> list[str]:
    errors: list[str] = []
    order = global_policy["governance_order"]
    rank = {name: index for index, name in enumerate(order)}
    global_rules = global_policy.get("hard_rules", {})
    for rule, project_level in project_policy.get("hard_rules", {}).items():
        if project_level not in rank:
            errors.append(f"project rule {rule} has invalid level {project_level}")
            continue
        if rule in global_rules and rank[project_level] < rank[global_rules[rule]]:
            errors.append(f"project rule {rule} weakens Global Baseline")
    minimum = project_policy.get("minimum_governance")
    if minimum is not None and minimum not in rank:
        errors.append(f"invalid project minimum_governance {minimum}")
    return errors


def required_files_missing(root: Path) -> list[str]:
    return [path for path in REQUIRED_FILES if not (root / path).is_file()]


def required_headings_missing(path: Path, headings: list[str]) -> list[str]:
    text = path.read_text(encoding="utf-8")
    return [heading for heading in headings if heading not in text]


def validate_package(root: Path) -> list[str]:
    errors: list[str] = []
    for missing in required_files_missing(root):
        errors.append(f"missing required file: {missing}")
    if errors:
        return errors

    global_policy = load_json(root / "policy/global-baseline.json")
    project_policy = load_json(root / "policy/project-policy.example.json")
    errors.extend(validate_global_policy(global_policy))
    errors.extend(validate_project_policy(global_policy, project_policy))

    for heading in required_headings_missing(root / "templates/root-AGENTS.md", ROOT_AGENT_HEADINGS):
        errors.append(f"root-AGENTS missing heading: {heading}")

    master_prompt = (root / "prompts/master-operating-prompt.md").read_text(encoding="utf-8")
    for phrase in [
        "Hard Rules are evaluated before the weighted risk score",
        "Do not scan the full repository by default",
        "Do not bypass a required human approval gate",
        "Stop and re-plan",
        "Persist current state in the checkpoint",
        "Parallelize only independent work",
    ]:
        if phrase not in master_prompt:
            errors.append(f"master prompt missing safety phrase: {phrase}")
    return errors


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    root = Path(args[0]) if args else Path("acpw")
    errors = validate_package(root)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"ACPW package valid: {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
