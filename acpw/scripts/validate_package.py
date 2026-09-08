from pathlib import Path
import json

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


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def validate_global_policy(policy: dict) -> list[str]:
    errors: list[str] = []
    if policy.get("governance_order") != ["Lightweight", "Standard", "Enterprise"]:
        errors.append("governance_order must be Lightweight, Standard, Enterprise")
    expected_weights = {
        "architecture": 25,
        "security": 25,
        "data": 20,
        "delivery": 20,
        "operations": 10,
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


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Validate ACPW package completeness")
    parser.add_argument("root", nargs="?", default=".", type=Path)
    args = parser.parse_args(argv)
    missing = required_files_missing(args.root)
    if missing:
        for path in missing:
            print(path)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
