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

MANDATORY_HARD_RULE_FLOORS = {
    "production_database_schema_migration": "Enterprise",
    "destructive_mass_data_modification": "Enterprise",
    "production_data_restore": "Enterprise",
    "disaster_recovery_or_failover": "Enterprise",
    "core_firewall_routing_or_critical_vpn_change": "Enterprise",
    "privileged_iam_change": "Enterprise",
    "private_or_encryption_key_rotation": "Enterprise",
    "production_cicd_control_plane_change": "Enterprise",
    "critical_filesystem_or_storage_change": "Enterprise",
    "production_secrets_migration": "Enterprise",
    "irreversible_production_operation": "Enterprise",
    "normal_production_application_deployment": "Standard",
    "production_configuration_change": "Standard",
    "non_core_firewall_rule_change": "Standard",
    "normal_user_permission_change": "Standard",
    "certificate_renewal": "Standard",
    "backup_policy_or_configuration_change": "Standard",
    "normal_os_or_server_configuration_change": "Standard",
    "standard_cicd_modification": "Standard",
    "dns_load_balancer_or_reverse_proxy_change": "Standard",
}

REQUIRED_APPROVAL_GATES = {
    "Lightweight": ["plan_approval"],
    "Standard": ["plan_approval", "release_or_deployment_approval"],
    "Enterprise": ["design_or_change_plan_approval", "pre_deployment_approval"],
}

REQUIRED_RETRY_BUDGETS = {"Lightweight": 2, "Standard": 3, "Enterprise": 3}


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def validate_global_policy(policy: dict) -> list[str]:
    errors: list[str] = []
    if not isinstance(policy, dict):
        return ["global policy must be a JSON object"]

    order = policy.get("governance_order")
    expected_order = ["Lightweight", "Standard", "Enterprise"]
    if order != expected_order:
        errors.append("governance_order must be Lightweight, Standard, Enterprise")

    expected_weights = {
        "security": 25,
        "data_production": 25,
        "blast_radius": 20,
        "reversibility": 15,
        "business_operational_impact": 10,
        "complexity": 5,
    }
    weights = policy.get("risk_weights")
    if not isinstance(weights, dict):
        errors.append("risk_weights must be an object")
    else:
        if not all(isinstance(value, (int, float)) and not isinstance(value, bool) for value in weights.values()):
            errors.append("risk_weights values must be numbers")
        elif sum(weights.values()) != 100:
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

    hard_rules = policy.get("hard_rules")
    if not isinstance(hard_rules, dict):
        errors.append("hard_rules must be an object")
    else:
        for name, required_level in MANDATORY_HARD_RULE_FLOORS.items():
            actual = hard_rules.get(name)
            if actual != required_level:
                errors.append(f"hard rule {name} must have minimum {required_level}")
        for name, level in hard_rules.items():
            if not isinstance(level, str) or level not in {"Standard", "Enterprise"}:
                errors.append(f"hard rule {name} has invalid minimum {level}")

    approval_gates = policy.get("approval_gates")
    if not isinstance(approval_gates, dict):
        errors.append("approval_gates must be an object")
    else:
        for governance, required in REQUIRED_APPROVAL_GATES.items():
            actual = approval_gates.get(governance)
            if not isinstance(actual, list) or any(not isinstance(gate, str) for gate in actual):
                errors.append(f"approval_gates.{governance} must be a list of gate names")
            elif any(gate not in actual for gate in required):
                errors.append(f"approval_gates.{governance} must include {', '.join(required)}")

    retry_budget = policy.get("retry_budget")
    if not isinstance(retry_budget, dict):
        errors.append("retry_budget must be an object")
    else:
        for governance, minimum in REQUIRED_RETRY_BUDGETS.items():
            actual = retry_budget.get(governance)
            if not isinstance(actual, int) or isinstance(actual, bool) or actual < 1 or actual > minimum:
                errors.append(f"retry_budget.{governance} must be an integer between 1 and {minimum}")

    if policy.get("full_repository_scan_default") is not False:
        errors.append("full_repository_scan_default must be false")
    return errors


def validate_project_policy(global_policy: dict, project_policy: dict) -> list[str]:
    errors: list[str] = []
    if not isinstance(global_policy, dict):
        return ["global policy must be an object"]
    if not isinstance(project_policy, dict):
        return ["project policy must be an object"]
    order = global_policy.get("governance_order")
    if not isinstance(order, list) or any(not isinstance(name, str) for name in order):
        return ["project policy cannot be checked until governance_order is valid"]
    rank = {name: index for index, name in enumerate(order)}
    global_rules = global_policy.get("hard_rules", {})
    if not isinstance(global_rules, dict):
        return ["project policy cannot be checked until hard_rules is valid"]
    project_rules = project_policy.get("hard_rules", {})
    if not isinstance(project_rules, dict):
        errors.append("project hard_rules must be an object")
    else:
        for rule, project_level in project_rules.items():
            if not isinstance(project_level, str) or project_level not in rank:
                errors.append(f"project rule {rule} has invalid level {project_level}")
                continue
            if rule in global_rules and rank[project_level] < rank[global_rules[rule]]:
                errors.append(f"project rule {rule} weakens Global Baseline")
    minimum = project_policy.get("minimum_governance")
    if minimum is not None and (not isinstance(minimum, str) or minimum not in rank):
        errors.append(f"invalid project minimum_governance {minimum}")
    return errors


def required_files_missing(root: Path) -> list[str]:
    return [path for path in REQUIRED_FILES if not (root / path).is_file()]


def required_headings_missing(path: Path, headings: list[str]) -> list[str]:
    text = path.read_text(encoding="utf-8")
    return [heading for heading in headings if heading not in text]


def _load_policy(path: Path, label: str) -> tuple[dict | None, list[str]]:
    try:
        value = load_json(path)
    except FileNotFoundError:
        return None, [f"{label} missing"]
    except json.JSONDecodeError as exc:
        return None, [f"{label} invalid JSON: {exc.msg} (line {exc.lineno}, column {exc.colno})"]
    except (OSError, UnicodeError) as exc:
        return None, [f"{label} could not be read: {exc}"]
    if not isinstance(value, dict):
        return None, [f"{label} must be a JSON object"]
    return value, []


def validate_package(root: Path) -> list[str]:
    errors: list[str] = []
    for missing in required_files_missing(root):
        errors.append(f"missing required file: {missing}")
    if errors:
        return errors

    global_policy, load_errors = _load_policy(root / "policy/global-baseline.json", "global-baseline.json")
    if load_errors:
        return load_errors
    global_errors = validate_global_policy(global_policy)
    errors.extend(global_errors)
    if global_errors:
        return errors

    project_policy, load_errors = _load_policy(root / "policy/project-policy.example.json", "project-policy.example.json")
    if load_errors:
        return load_errors
    errors.extend(validate_project_policy(global_policy, project_policy))

    try:
        missing_headings = required_headings_missing(root / "templates/root-AGENTS.md", ROOT_AGENT_HEADINGS)
    except (OSError, UnicodeError) as exc:
        errors.append(f"root-AGENTS.md could not be read: {exc}")
        missing_headings = []
    for heading in missing_headings:
        errors.append(f"root-AGENTS missing heading: {heading}")

    try:
        master_prompt = (root / "prompts/master-operating-prompt.md").read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        errors.append(f"master-operating-prompt.md could not be read: {exc}")
        master_prompt = ""
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
