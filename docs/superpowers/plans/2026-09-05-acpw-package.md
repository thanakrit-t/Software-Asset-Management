# ACPW Reusable Package Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a portable ACPW v1.0 package that can be dropped into any Codex-capable project to enforce adaptive governance, bounded usage, layered context, structured checkpoints, progressive verification, and resumable execution.

**Architecture:** Implement ACPW as a tool-agnostic policy-and-template kit under `acpw/`, with a machine-readable global policy in JSON, Markdown templates/prompts for humans and Codex, and a dependency-free Python validator that checks package completeness and cross-file consistency. The package must not require a project to adopt a specific language, CI system, or deployment platform.

**Tech Stack:** Markdown, JSON, Python 3.10+ standard library (`json`, `pathlib`, `unittest`), Git.

**Spec:** `docs/superpowers/specs/2026-09-05-acpw-design.md`

## Global Constraints

- Governance levels are exactly `Lightweight`, `Standard`, and `Enterprise`.
- Risk weights are fixed at Security 25%, Data/Production 25%, Blast Radius 20%, Reversibility 15%, Business/Operational Impact 10%, Complexity 5%.
- Risk thresholds are fixed at 0–29 Lightweight, 30–64 Standard, and 65–100 Enterprise.
- Final governance level is the maximum of risk-score level, Global Hard Rule minimum, and Project Policy minimum.
- Project policy may raise rigor but must never weaken the Global Baseline.
- Hard Rules are evaluated before the weighted risk score.
- Enterprise production actions remain human approval-gated.
- Governance risk and reasoning difficulty remain separate dimensions.
- Full-repository scanning is not the default and must be justified.
- Every task must have an explicit budget and stop conditions.
- Verification proceeds from cheap/fast checks to broader/expensive checks.
- Current work state is persisted in a structured checkpoint rather than recovered from chat history.
- No external Python dependencies are allowed for validation.

---

## Target File Map

```text
acpw/
├── README.md
├── policy/
│   ├── global-baseline.json
│   └── project-policy.example.json
├── templates/
│   ├── root-AGENTS.md
│   ├── module-AGENTS.md
│   ├── task.md
│   ├── checkpoint.md
│   ├── risk-assessment.md
│   ├── change-standard.md
│   ├── change-enterprise.md
│   ├── evidence-lightweight.md
│   ├── evidence-standard.md
│   └── evidence-enterprise.md
├── prompts/
│   ├── master-operating-prompt.md
│   ├── session-start.md
│   └── session-end.md
├── docs/
│   ├── rollout-checklist.md
│   └── verification-plan.md
├── scripts/
│   └── validate_package.py
└── tests/
    └── test_validate_package.py
```

Responsibilities:

- `policy/global-baseline.json`: canonical machine-readable ACPW defaults, thresholds, hard-rule floors, approval gates, execution budgets, and verification/evidence requirements.
- `policy/project-policy.example.json`: example of legal project-level tightening without weakening the baseline.
- `templates/*`: reusable project/task/change/evidence artifacts.
- `prompts/*`: reusable operating instructions for Codex and session handoff.
- `scripts/validate_package.py`: validates required files, policy invariants, template headings, and prompt safety requirements.
- `tests/test_validate_package.py`: regression tests for the validator and core ACPW invariants.
- `docs/*`: rollout guidance and self-verification procedure.
- `README.md`: shortest path to adopt ACPW in a new or existing project.

---

### Task 1: Create the ACPW package skeleton and completeness validator

**Files:**
- Create: `acpw/scripts/validate_package.py`
- Create: `acpw/tests/test_validate_package.py`
- Create: all directories from the Target File Map

**Interfaces:**
- Consumes: approved ACPW design spec.
- Produces: `REQUIRED_FILES`, `required_files_missing(root: Path) -> list[str]`, and a CLI entry point returning exit code `0` for a complete package and `1` for validation failure.

- [ ] **Step 1: Write the failing completeness test**

Create `acpw/tests/test_validate_package.py` with:

```python
import tempfile
import unittest
from pathlib import Path

from acpw.scripts.validate_package import REQUIRED_FILES, required_files_missing


class PackageCompletenessTests(unittest.TestCase):
    def test_empty_package_reports_every_required_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            missing = required_files_missing(Path(tmp))
            self.assertEqual(sorted(missing), sorted(REQUIRED_FILES))


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run the test and verify it fails because the validator module does not exist**

Run:

```bash
python -m unittest acpw.tests.test_validate_package -v
```

Expected: `ModuleNotFoundError` for `acpw.scripts.validate_package`.

- [ ] **Step 3: Implement the minimal completeness validator**

Create `acpw/scripts/validate_package.py` with:

```python
from pathlib import Path

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


def required_files_missing(root: Path) -> list[str]:
    return [path for path in REQUIRED_FILES if not (root / path).is_file()]
```

- [ ] **Step 4: Run the test and verify it passes**

Run:

```bash
python -m unittest acpw.tests.test_validate_package -v
```

Expected: `OK`.

- [ ] **Step 5: Create empty target directories only; do not create placeholder content files yet**

Run:

```bash
mkdir -p acpw/policy acpw/templates acpw/prompts acpw/docs acpw/scripts acpw/tests
```

Expected: all target directories exist.

- [ ] **Step 6: Commit the validator skeleton**

```bash
git add acpw/scripts/validate_package.py acpw/tests/test_validate_package.py
git commit -m "test(acpw): add package completeness validator"
```

---

### Task 2: Encode the Global Baseline and project-policy precedence

**Files:**
- Create: `acpw/policy/global-baseline.json`
- Create: `acpw/policy/project-policy.example.json`
- Modify: `acpw/scripts/validate_package.py`
- Modify: `acpw/tests/test_validate_package.py`

**Interfaces:**
- Consumes: Global Constraints from this plan.
- Produces: `load_json(path: Path) -> dict`, `validate_global_policy(policy: dict) -> list[str]`, `validate_project_policy(global_policy: dict, project_policy: dict) -> list[str]`.

- [ ] **Step 1: Add failing tests for weights, thresholds, hard-rule floors, and non-weakening project policy**

Append to `acpw/tests/test_validate_package.py`:

```python
import json

from acpw.scripts.validate_package import (
    load_json,
    validate_global_policy,
    validate_project_policy,
)


class PolicyTests(unittest.TestCase):
    def test_global_policy_has_no_invariant_errors(self):
        policy = load_json(Path("acpw/policy/global-baseline.json"))
        self.assertEqual(validate_global_policy(policy), [])

    def test_project_policy_may_raise_but_not_lower_a_hard_rule(self):
        global_policy = {
            "governance_order": ["Lightweight", "Standard", "Enterprise"],
            "hard_rules": {"prod_deploy": "Standard"},
        }
        raised = {"hard_rules": {"prod_deploy": "Enterprise"}}
        lowered = {"hard_rules": {"prod_deploy": "Lightweight"}}
        self.assertEqual(validate_project_policy(global_policy, raised), [])
        self.assertTrue(validate_project_policy(global_policy, lowered))
```

- [ ] **Step 2: Run the tests and verify they fail because policy functions/files do not exist**

Run:

```bash
python -m unittest acpw.tests.test_validate_package -v
```

Expected: import or file-not-found failures for the policy layer.

- [ ] **Step 3: Create the exact Global Baseline JSON**

Create `acpw/policy/global-baseline.json`:

```json
{
  "version": "1.0",
  "governance_order": ["Lightweight", "Standard", "Enterprise"],
  "risk_weights": {
    "security": 25,
    "data_production": 25,
    "blast_radius": 20,
    "reversibility": 15,
    "business_operational_impact": 10,
    "complexity": 5
  },
  "thresholds": {
    "Lightweight": [0, 29],
    "Standard": [30, 64],
    "Enterprise": [65, 100]
  },
  "hard_rules": {
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
    "dns_load_balancer_or_reverse_proxy_change": "Standard"
  },
  "approval_gates": {
    "Lightweight": ["plan_approval"],
    "Standard": ["plan_approval", "release_or_deployment_approval"],
    "Enterprise": ["design_or_change_plan_approval", "pre_deployment_approval"]
  },
  "retry_budget": {
    "Lightweight": 2,
    "Standard": 3,
    "Enterprise": 3
  },
  "full_repository_scan_default": false
}
```

- [ ] **Step 4: Create a project policy example that only tightens the baseline**

Create `acpw/policy/project-policy.example.json`:

```json
{
  "project": "example-project",
  "minimum_governance": "Standard",
  "hard_rules": {
    "certificate_renewal": "Enterprise",
    "normal_production_application_deployment": "Enterprise"
  },
  "notes": "Project policy may add stricter controls but must never lower the Global Baseline."
}
```

- [ ] **Step 5: Implement JSON loading and invariant validation**

Add to `acpw/scripts/validate_package.py`:

```python
import json


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def validate_global_policy(policy: dict) -> list[str]:
    errors: list[str] = []
    order = policy.get("governance_order")
    if order != ["Lightweight", "Standard", "Enterprise"]:
        errors.append("governance_order must be Lightweight, Standard, Enterprise")
    if sum(policy.get("risk_weights", {}).values()) != 100:
        errors.append("risk_weights must sum to 100")
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
```

- [ ] **Step 6: Run tests and verify they pass**

Run:

```bash
python -m unittest acpw.tests.test_validate_package -v
```

Expected: `OK`.

- [ ] **Step 7: Commit the policy layer**

```bash
git add acpw/policy acpw/scripts/validate_package.py acpw/tests/test_validate_package.py
git commit -m "feat(acpw): encode global governance baseline"
```

---

### Task 3: Create layered context templates for root and module AGENTS files

**Files:**
- Create: `acpw/templates/root-AGENTS.md`
- Create: `acpw/templates/module-AGENTS.md`
- Modify: `acpw/scripts/validate_package.py`
- Modify: `acpw/tests/test_validate_package.py`

**Interfaces:**
- Consumes: layered context rules from the spec.
- Produces: templates with stable headings that the validator can verify.

- [ ] **Step 1: Add a failing heading-validation test**

Append:

```python
from acpw.scripts.validate_package import required_headings_missing


class ContextTemplateTests(unittest.TestCase):
    def test_root_agents_contains_required_sections(self):
        missing = required_headings_missing(
            Path("acpw/templates/root-AGENTS.md"),
            [
                "# Project Purpose",
                "# Global Architecture",
                "# ACPW Governance",
                "# Context Loading Rules",
                "# Security Baseline",
                "# Verification Commands",
                "# Definition of Done",
            ],
        )
        self.assertEqual(missing, [])
```

- [ ] **Step 2: Run tests and verify failure**

Expected: missing function/file failure.

- [ ] **Step 3: Create `root-AGENTS.md` with exact operating sections**

Create:

```markdown
# Project Purpose
State the system purpose, primary users, and business outcome in concise project-specific language.

# Global Architecture
Describe only stable system boundaries, major components, data stores, external dependencies, and deployment topology. Link detailed diagrams from `docs/architecture/` instead of duplicating them here.

# ACPW Governance
Use the Global Baseline from `acpw/policy/global-baseline.json`. Apply any stricter project policy. Classify each task before execution. Hard Rules set a non-reducible minimum. Human override may raise rigor but may not lower the Safety Floor.

# Reasoning Routing
Governance measures consequence if wrong. Reasoning measures difficulty of solving correctly. Start with the lowest sufficient reasoning and escalate only when evidence requires it.

# Context Loading Rules
Read this file, the relevant module `AGENTS.md`, `docs/checkpoints/current.md`, and only files needed for the current task. Do not scan the full repository unless the task explicitly requires it and the plan records the justification.

# Execution Rules
Every task requires a goal, scope, out-of-scope boundary, acceptance criteria, verification plan, execution budget, and stop conditions. Stop and re-plan on material scope, risk, root-cause, dependency, rollback, or production-action changes.

# Security Baseline
Do not expose secrets. Do not perform destructive or privileged actions without the governance level and approval required by ACPW. Preserve rollback viability for Standard and Enterprise changes where applicable.

# Verification Commands
List project-specific syntax, lint, static analysis, unit, integration, regression, configuration-validation, and health-check commands in cheapest-to-broadest order.

# Git and Isolation
Do not discard unrelated user work. Use isolation proportional to governance level. Record the baseline and rollback point for Standard and Enterprise work.

# Documentation Sources of Truth
Architecture: `docs/architecture/`  
Decisions: `docs/decisions/`  
Current status: `docs/checkpoints/current.md`  
Runbooks: `docs/runbooks/`  
Change plans: `docs/changes/`  
Evidence: `docs/evidence/`  
Releases: `docs/releases/`

# Definition of Done
The task goal is achieved; acceptance criteria pass; verification passes; scope did not expand unintentionally; required security/data review is complete; evidence is updated; the checkpoint is updated; a commit or equivalent change record exists; rollback remains viable where required; and the exact next task is known if work continues.
```

- [ ] **Step 4: Create `module-AGENTS.md`**

Create:

```markdown
# Module Purpose
Describe the single responsibility of this module and its externally visible behavior.

# Boundaries
List what belongs in this module and what explicitly does not.

# Interfaces
Document stable inputs, outputs, APIs, events, data contracts, ports, or operational entry points used by other modules.

# Dependencies
List only dependencies required to understand or modify this module safely.

# Module-Specific Rules
Record local conventions that are stricter or more specific than the root `AGENTS.md`. Never weaken root ACPW policy.

# Verification
List the fastest targeted checks for this module, followed by integration checks that cover its consumers or dependencies.

# Known Risks
List persistent module-specific risks or sensitive operations that should affect task assessment.

# Relevant Documentation
Link module architecture, runbooks, decisions, and evidence instead of copying them into this file.
```

- [ ] **Step 5: Implement `required_headings_missing`**

Add:

```python
def required_headings_missing(path: Path, headings: list[str]) -> list[str]:
    text = path.read_text(encoding="utf-8")
    return [heading for heading in headings if heading not in text]
```

- [ ] **Step 6: Run the tests**

Expected: `OK`.

- [ ] **Step 7: Commit the context templates**

```bash
git add acpw/templates/root-AGENTS.md acpw/templates/module-AGENTS.md acpw/scripts/validate_package.py acpw/tests/test_validate_package.py
git commit -m "docs(acpw): add layered context templates"
```

---

### Task 4: Create task, risk, checkpoint, change-plan, and evidence templates

**Files:**
- Create: `acpw/templates/task.md`
- Create: `acpw/templates/checkpoint.md`
- Create: `acpw/templates/risk-assessment.md`
- Create: `acpw/templates/change-standard.md`
- Create: `acpw/templates/change-enterprise.md`
- Create: `acpw/templates/evidence-lightweight.md`
- Create: `acpw/templates/evidence-standard.md`
- Create: `acpw/templates/evidence-enterprise.md`
- Modify: `acpw/tests/test_validate_package.py`

**Interfaces:**
- Consumes: task slicing, stop conditions, checkpoint, evidence, and approval requirements.
- Produces: copy-ready Markdown artifacts with stable field names used by Codex across sessions.

- [ ] **Step 1: Add failing tests for required template fields**

Append tests that call `required_headings_missing` and assert no missing headings for:

```python
TEMPLATE_REQUIREMENTS = {
    "task.md": ["# Task ID", "# Goal", "# In Scope", "# Out of Scope", "# Acceptance Criteria", "# Execution Budget", "# Stop Conditions"],
    "checkpoint.md": ["# Project", "# Task ID", "# Current State", "# Tests Performed", "# Next Task", "# Do Not Re-read", "# Rollback Point"],
    "risk-assessment.md": ["# Hard Rule Check", "# Weighted Risk Score", "# Final Governance Level", "# Reasoning Level"],
    "change-standard.md": ["# Scope", "# Rollback Note", "# Release / Deployment Approval"],
    "change-enterprise.md": ["# Risk Assessment", "# Impact Assessment", "# Rollback Plan", "# Pre-Deployment Approval", "# Post-Change Verification"],
}
```

Expected initial result: failures because the templates do not yet exist.

- [ ] **Step 2: Create `task.md`**

```markdown
# Task ID
Use a stable project-local identifier.

# Goal
State one outcome only.

# Governance Level
Record Lightweight, Standard, or Enterprise and the reason.

# Reasoning Level
Record Low, Medium, or High independently from governance.

# In Scope
List only files, systems, modules, or actions required for this task.

# Out of Scope
List adjacent work that must not be pulled into this task.

# Required Context
List the root policy, relevant module policy, checkpoint, and exact additional files/docs needed.

# Dependencies
List prerequisites and outputs required from earlier tasks.

# Acceptance Criteria
Write observable pass/fail conditions.

# Verification
List checks from cheapest to broadest.

# Execution Budget
Record allowed exploration scope, retry count, cross-module limits, and whether full-repository scanning is forbidden or justified.

# Stop Conditions
Stop on unexpected scope expansion, material architecture change, new security/data-loss risk, destructive action, unapproved production action, root-cause change, repeated verification failure beyond budget, major dependency addition, unknown uncommitted changes, excessive context growth, invalid rollback, or unexpected secrets.
```

- [ ] **Step 3: Create `checkpoint.md`**

```markdown
# Project

# Phase

# Module

# Task ID

# Governance Level

# Reasoning Level

# Status

# Goal

# Completed

# Current State

# Decisions

# Files / Systems Changed

# Tests Performed

# Test Results

# Known Issues

# Risks

# Open Questions

# Next Task

# Required Context

# Do Not Re-read
Record repository areas or documents already proven irrelevant to the next task.

# Branch

# Last Commit

# Rollback Point
```

- [ ] **Step 4: Create `risk-assessment.md`**

```markdown
# Hard Rule Check
List matching Global or Project Hard Rules and their minimum governance level. If none match, write `None`.

# Weighted Risk Score
Score each factor from 0–5, then calculate its weighted contribution:

| Factor | Score 0-5 | Weight | Contribution |
|---|---:|---:|---:|
| Security |  | 25% |  |
| Data / Production |  | 25% |  |
| Blast Radius |  | 20% |  |
| Reversibility |  | 15% |  |
| Business / Operational Impact |  | 10% |  |
| Complexity |  | 5% |  |

Normalize the total to 0–100. Map 0–29 to Lightweight, 30–64 to Standard, and 65–100 to Enterprise.

# Project Policy Minimum
Record the project-specific minimum if one exists.

# Final Governance Level
Use the maximum of Risk Score Level, Global Hard Rule Minimum, and Project Policy Minimum.

# Reasoning Level
Select Low, Medium, or High based on problem-solving difficulty rather than production consequence.

# Human Decision
Record approval or an upward override. A downward override may not cross the Safety Floor.
```

- [ ] **Step 5: Create Standard and Enterprise change templates**

`change-standard.md`:

```markdown
# Change Summary

# Scope

# Baseline
Record branch/environment and baseline commit or configuration version.

# Implementation Plan
List ordered actions only within the approved scope.

# Verification Plan
List syntax/config checks, targeted/unit tests, related integration tests, and impacted regression checks as applicable.

# Rollback Note
State the known-good rollback point and the trigger for rollback.

# Plan Approval
Record who approved the plan and when.

# Release / Deployment Approval
Required before applying the change to the target environment.

# Post-Change Verification
Record the health checks and acceptance criteria used after deployment.
```

`change-enterprise.md`:

```markdown
# Change Summary

# Scope

# Baseline and Isolation
Record dedicated branch/worktree/environment, approved baseline, and rollback point.

# Risk Assessment
Reference the completed risk-assessment artifact.

# Impact Assessment
Document affected services, users, data, dependencies, blast radius, and expected downtime/degradation.

# Implementation Plan
List ordered actions and explicit checkpoints.

# Verification Plan
List static/config checks, targeted/unit tests, integration tests, security/data validation, staging/pre-production checks, regression checks, deployment validation, and post-change health checks as applicable.

# Rollback Plan
Document exact rollback steps, required backups/snapshots/config versions, estimated rollback time, and validation after rollback.

# Rollback Verification
Record evidence that the rollback path is viable before production execution.

# Design / Change Plan Approval
Required before implementation begins.

# Pre-Deployment Approval
Required immediately before the production or equivalent high-risk action.

# Deployment Record
Record ordered actions, timestamps/change identifiers, and deviations.

# Post-Change Verification
Record acceptance checks, data validation, service health, and monitoring results.

# Exceptions
Record approved deviations or write `None`.

# Closeout
Confirm evidence, checkpoint, rollback state, and next task.
```

- [ ] **Step 6: Create the three evidence templates**

`evidence-lightweight.md` contains headings `# Change Summary`, `# Tests Performed`, `# Result`, `# Commit / Change Reference`, `# Checkpoint Updated`.

`evidence-standard.md` contains headings `# Change Summary`, `# Components Changed`, `# Decisions`, `# Test Evidence`, `# Known Limitations`, `# Rollback Note`, `# Commit / Change Reference`, `# Checkpoint Updated`.

`evidence-enterprise.md` contains headings `# Approved Change Plan`, `# Risk Assessment`, `# Impact Assessment`, `# Implementation Record`, `# Test Evidence`, `# Security / Data Evidence`, `# Rollback Procedure`, `# Rollback Verification`, `# Deployment Record`, `# Post-Change Validation`, `# Decisions / Exceptions`, `# Audit Closeout`.

- [ ] **Step 7: Run all template tests**

Run:

```bash
python -m unittest acpw.tests.test_validate_package -v
```

Expected: `OK`.

- [ ] **Step 8: Commit the artifact templates**

```bash
git add acpw/templates acpw/tests/test_validate_package.py
git commit -m "docs(acpw): add execution and evidence templates"
```

---

### Task 5: Create the Master Codex operating prompt and session protocols

**Files:**
- Create: `acpw/prompts/master-operating-prompt.md`
- Create: `acpw/prompts/session-start.md`
- Create: `acpw/prompts/session-end.md`
- Modify: `acpw/tests/test_validate_package.py`

**Interfaces:**
- Consumes: policy and templates from Tasks 2–4.
- Produces: a reusable prompt that instructs Codex to apply ACPW without rereading the entire repository or bypassing safety gates.

- [ ] **Step 1: Add failing tests for mandatory prompt controls**

Append:

```python
class PromptSafetyTests(unittest.TestCase):
    def test_master_prompt_contains_non_negotiable_controls(self):
        text = Path("acpw/prompts/master-operating-prompt.md").read_text(encoding="utf-8")
        required = [
            "Hard Rules are evaluated before the weighted risk score",
            "Do not scan the full repository by default",
            "Do not bypass a required human approval gate",
            "Stop and re-plan",
            "Persist current state in the checkpoint",
            "Parallelize only independent work",
        ]
        for phrase in required:
            self.assertIn(phrase, text)
```

- [ ] **Step 2: Run tests and verify the prompt test fails**

Expected: file-not-found failure.

- [ ] **Step 3: Create `master-operating-prompt.md`**

Use this exact content:

```markdown
# ACPW Master Operating Prompt

You are operating under Adaptive Codex Project Workflow (ACPW) v1.0.

## 1. Establish the task before execution
Inspect existing project context first. Determine the goal, target environment/system/module, current state, expected result, in-scope and out-of-scope boundaries, production/security/data/destructive implications, rollback viability, dependencies, and acceptance criteria. Ask only for information that cannot be determined safely.

## 2. Classify governance
Hard Rules are evaluated before the weighted risk score. Apply the Global Baseline, then any stricter Project Policy. Calculate the weighted score using Security 25%, Data/Production 25%, Blast Radius 20%, Reversibility 15%, Business/Operational Impact 10%, and Complexity 5%. Map 0–29 to Lightweight, 30–64 to Standard, and 65–100 to Enterprise. The Final Governance Level is the maximum of risk-score level, Hard Rule minimum, and Project Policy minimum. Human approval may raise rigor but may not weaken the Safety Floor.

## 3. Route reasoning separately
Governance measures consequence if wrong. Reasoning measures difficulty of solving correctly. Start with the lowest sufficient reasoning and escalate only when evidence shows unresolved ambiguity, competing hypotheses, architecture conflict, cross-system dependency, or new security implications.

## 4. Load minimum context
Read the root `AGENTS.md`, the relevant module `AGENTS.md`, `docs/checkpoints/current.md`, and only the files/docs required by the current task. Do not scan the full repository by default. Record a justification before any broad scan.

## 5. Slice the task
Use one clear goal per task. Define scope, out-of-scope boundary, required context, dependencies, acceptance criteria, verification, execution budget, and stop conditions. Split work when context, dependency, or risk makes a task too broad.

## 6. Approval and isolation
Do not bypass a required human approval gate. Use isolation proportional to governance level. Never discard unrelated user work, hard-reset unknown changes, or overwrite unrelated files without explicit authorization.

## 7. Execute within budget
Use targeted exploration. Debug by evidence and hypotheses, not random edits. Respect retry limits. Parallelize only independent work with no overlapping files/state and a known integration path.

## 8. Stop conditions
Stop and re-plan when scope expands materially, architecture must change, new security/data-loss risk appears, destructive action becomes necessary, production action lacks approval, the root cause materially changes, tests fail beyond budget, a major dependency is required, unknown uncommitted changes appear, context becomes too broad, rollback becomes invalid, or unexpected secrets are encountered.

## 9. Verify progressively
Run the cheapest relevant validation first. Do not run broader/expensive verification while a cheaper prerequisite is failing. Expand from syntax/config validation to targeted/unit tests, module/integration tests, impacted regression, and full/staging/deployment validation only as the governance level and change impact require.

## 10. Persist state and evidence
Persist current state in the checkpoint. Update evidence proportional to governance level. Use the documented single sources of truth rather than duplicating project knowledge across files.

## 11. Close the task
A task is complete only when its goal and acceptance criteria are met, applicable verification passes, scope did not expand unintentionally, required risk review is complete, evidence and checkpoint are updated, a commit or equivalent change record exists, rollback remains viable where required, and the exact next task is known if work continues.
```

- [ ] **Step 4: Create `session-start.md`**

```markdown
# ACPW Session Start

1. Read root `AGENTS.md`.
2. Read the relevant module `AGENTS.md`.
3. Read `docs/checkpoints/current.md`.
4. Check branch/worktree/environment status and note unknown changes.
5. Inspect only files/systems required by the checkpoint's Next Task.
6. Confirm the current Task ID, Governance Level, Reasoning Level, scope, budget, stop conditions, and required approvals.
7. Continue only if the task state is internally consistent; otherwise stop and report the inconsistency.
```

- [ ] **Step 5: Create `session-end.md`**

```markdown
# ACPW Session End

1. Run the verification required for the current governance level and task scope.
2. Summarize completed changes and unresolved issues.
3. Update `docs/checkpoints/current.md` with current state, tests/results, risks, branch, last commit/change identifier, rollback point, required context, do-not-re-read guidance, and exact Next Task.
4. Update the evidence artifact required by the governance level.
5. Confirm no unrelated user work was discarded or overwritten.
6. Confirm rollback viability where required.
7. Stop after the handoff artifact is sufficient for a new session to continue without a repository-wide rediscovery pass.
```

- [ ] **Step 6: Run tests and verify they pass**

Expected: `OK`.

- [ ] **Step 7: Commit the operating prompts**

```bash
git add acpw/prompts acpw/tests/test_validate_package.py
git commit -m "docs(acpw): add master operating and session prompts"
```

---

### Task 6: Expand the validator to enforce package-wide consistency and safe CLI behavior

**Files:**
- Modify: `acpw/scripts/validate_package.py`
- Modify: `acpw/tests/test_validate_package.py`

**Interfaces:**
- Consumes: all policy/template/prompt files created in prior tasks.
- Produces: `validate_package(root: Path) -> list[str]`, `main(argv: list[str] | None = None) -> int`.

- [ ] **Step 1: Add failing end-to-end validation tests**

Append:

```python
from acpw.scripts.validate_package import validate_package


class EndToEndValidationTests(unittest.TestCase):
    def test_repository_acpw_package_validates_cleanly(self):
        self.assertEqual(validate_package(Path("acpw")), [])

    def test_missing_required_file_is_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            errors = validate_package(root)
            self.assertTrue(any("missing required file" in error for error in errors))
```

- [ ] **Step 2: Run tests and verify failure because `validate_package` is absent**

Expected: import failure.

- [ ] **Step 3: Implement full package validation**

Add to `validate_package.py`:

```python
ROOT_AGENT_HEADINGS = [
    "# Project Purpose",
    "# Global Architecture",
    "# ACPW Governance",
    "# Context Loading Rules",
    "# Security Baseline",
    "# Verification Commands",
    "# Definition of Done",
]


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
```

Add CLI behavior:

```python
import sys


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
```

- [ ] **Step 4: Run unit tests**

```bash
python -m unittest acpw.tests.test_validate_package -v
```

Expected: `OK`.

- [ ] **Step 5: Run the validator as a user would**

```bash
python acpw/scripts/validate_package.py acpw
```

Expected:

```text
ACPW package valid: acpw
```

- [ ] **Step 6: Commit the package validator**

```bash
git add acpw/scripts/validate_package.py acpw/tests/test_validate_package.py
git commit -m "feat(acpw): validate policy and prompt consistency"
```

---

### Task 7: Write rollout guidance, verification plan, and adoption README

**Files:**
- Create: `acpw/README.md`
- Create: `acpw/docs/rollout-checklist.md`
- Create: `acpw/docs/verification-plan.md`
- Modify: `acpw/tests/test_validate_package.py`

**Interfaces:**
- Consumes: the complete ACPW kit.
- Produces: a safe adoption path for new/existing projects and a repeatable self-test procedure.

- [ ] **Step 1: Add a failing documentation smoke test**

Append:

```python
class DocumentationTests(unittest.TestCase):
    def test_readme_contains_minimum_adoption_path(self):
        text = Path("acpw/README.md").read_text(encoding="utf-8")
        for phrase in [
            "Validate the ACPW package",
            "Copy the root AGENTS template",
            "Create the current checkpoint",
            "Do not weaken the Global Baseline",
        ]:
            self.assertIn(phrase, text)
```

- [ ] **Step 2: Run tests and verify README failure**

Expected: file-not-found failure.

- [ ] **Step 3: Create `README.md`**

```markdown
# Adaptive Codex Project Workflow (ACPW) v1.0

ACPW is a reusable governance and usage-optimization kit for software, infrastructure, cloud, network, security, database, CI/CD, migration, automation, troubleshooting, research/PoC, documentation, deployment, and operations work performed with Codex.

## Minimum Adoption Path

1. Validate the ACPW package: `python acpw/scripts/validate_package.py acpw`.
2. Copy the root AGENTS template from `acpw/templates/root-AGENTS.md` to the project root as `AGENTS.md`, then replace its generic project-description text with real project facts while preserving ACPW controls.
3. Copy `acpw/templates/module-AGENTS.md` into modules that need local context or stricter rules.
4. Create the current checkpoint at `docs/checkpoints/current.md` from `acpw/templates/checkpoint.md`.
5. Copy `acpw/policy/project-policy.example.json` to a project-controlled policy file only when stricter local rules are needed.
6. Start each new task from `acpw/templates/task.md` and `acpw/templates/risk-assessment.md`.
7. Use the Master Operating Prompt and the Session Start/End protocols for Codex execution.
8. Do not weaken the Global Baseline. Project rules may only raise governance rigor.

## Usage Optimization Rules

- Load context progressively; do not rediscover the repository each session.
- Keep one clear goal per task.
- Start with the lowest sufficient reasoning.
- Use explicit retry budgets and stop conditions.
- Run targeted verification before broad regression.
- Parallelize only independent work.
- Persist handoff state in the current checkpoint.

## Validation

Run `python -m unittest acpw.tests.test_validate_package -v` and then `python acpw/scripts/validate_package.py acpw` after modifying ACPW policy, templates, or prompts.
```

- [ ] **Step 4: Create `rollout-checklist.md`**

Include these exact checklist items:

```markdown
# ACPW Rollout Checklist

- [ ] Identify the project owner and operational owner.
- [ ] Record organization/legal/regulatory controls that are stricter than ACPW.
- [ ] Validate the unmodified ACPW package.
- [ ] Create project-root `AGENTS.md` from the root template.
- [ ] Add module `AGENTS.md` files only where local context materially reduces rediscovery.
- [ ] Create `docs/checkpoints/current.md`.
- [ ] Decide whether a stricter Project Policy is required.
- [ ] Document project verification commands from cheapest to broadest.
- [ ] Document branch/worktree/environment conventions.
- [ ] Pilot ACPW on one Lightweight task.
- [ ] Pilot ACPW on one Standard task.
- [ ] If the project performs high-risk production work, dry-run one Enterprise change plan without applying the production action.
- [ ] Confirm checkpoint handoff works in a fresh Codex session without a full-repository scan.
- [ ] Confirm users know that downward overrides cannot cross the Safety Floor.
- [ ] Confirm production approvals remain human-controlled.
- [ ] Record adoption date and owner in project documentation.
```

- [ ] **Step 5: Create `verification-plan.md`**

```markdown
# ACPW Workflow Verification Plan

## Package Integrity
Run `python -m unittest acpw.tests.test_validate_package -v` and `python acpw/scripts/validate_package.py acpw`. Both must pass.

## Governance Classification Scenario
Assess a normal production deployment. Expected minimum: Standard. Assess a production database schema migration. Expected minimum: Enterprise regardless of a lower weighted score.

## Project Policy Scenario
Raise certificate renewal from Standard to Enterprise in Project Policy. Validation must allow it. Attempt to lower production database schema migration from Enterprise to Standard. Validation or review must reject it.

## Context Scenario
Start a fresh session using root `AGENTS.md`, relevant module `AGENTS.md`, and `docs/checkpoints/current.md`. The worker must be able to identify the exact Next Task without a full-repository scan.

## Budget / Stop Scenario
Use a task with retry budget 2. Force two rejected hypotheses and then a third failure. Expected behavior: stop and re-plan rather than continue random edits.

## Verification Pyramid Scenario
Introduce a syntax/config error and a failing integration test. Expected behavior: stop at the cheap prerequisite failure before running broad regression.

## Isolation Scenario
Create unrelated uncommitted work before starting an ACPW task. Expected behavior: report and preserve the unrelated changes; do not hard-reset or discard them.

## Parallelism Scenario
Provide two independent documentation tasks and two tasks that edit the same configuration file. Expected behavior: the independent pair may run in parallel; overlapping-file tasks remain sequential.

## Enterprise Approval Scenario
Prepare an Enterprise production change. Expected behavior: implementation does not bypass design/change-plan approval or pre-deployment approval.

## Evidence and Handoff Scenario
End a Standard or Enterprise task and begin a new session. Expected behavior: evidence and checkpoint contain enough state to continue without relying on chat history.
```

- [ ] **Step 6: Run all tests and package validation**

```bash
python -m unittest acpw.tests.test_validate_package -v
python acpw/scripts/validate_package.py acpw
```

Expected: tests `OK`; validator prints `ACPW package valid: acpw`.

- [ ] **Step 7: Commit the adoption documentation**

```bash
git add acpw/README.md acpw/docs acpw/tests/test_validate_package.py
git commit -m "docs(acpw): add rollout and verification guidance"
```

---

### Task 8: Perform final spec-coverage verification and release ACPW v1.0

**Files:**
- Modify only if a verification gap is found: files under `acpw/`
- Read: `docs/superpowers/specs/2026-09-05-acpw-design.md`

**Interfaces:**
- Consumes: all outputs from Tasks 1–7.
- Produces: a validated ACPW v1.0 package and release-ready commit/tag recommendation.

- [ ] **Step 1: Run the complete unit test suite**

```bash
python -m unittest acpw.tests.test_validate_package -v
```

Expected: all tests pass with `OK`.

- [ ] **Step 2: Run package validation**

```bash
python acpw/scripts/validate_package.py acpw
```

Expected:

```text
ACPW package valid: acpw
```

- [ ] **Step 3: Walk the spec section-by-section and map each requirement to a package artifact**

Record the mapping in the implementation session notes. At minimum verify:

```text
Governance + Hard Rules       -> policy/global-baseline.json + master prompt
Reasoning Routing             -> master prompt + root-AGENTS
Layered Context               -> root/module AGENTS + session-start
Task Slicing/Budget/Stops      -> task template + master prompt
Parallelism                   -> master prompt
Isolation                     -> root-AGENTS + change templates
Verification Pyramid          -> root-AGENTS + change templates + verification plan
Checkpoint                    -> checkpoint template + session protocols
Evidence                      -> evidence templates
Single Source of Truth        -> root-AGENTS
Commit / DoD                  -> root-AGENTS + master prompt
Rollout / Adoption            -> README + rollout checklist
Workflow Self-Verification    -> tests + validator + verification plan
```

- [ ] **Step 4: Search for forbidden placeholders in shipped ACPW files**

Run:

```bash
python - <<'PY2'
from pathlib import Path
patterns = ['T' + 'BD', 'T' + 'ODO', 'implement ' + 'later', 'fill in ' + 'details', 'fix ' + 'stuff', 'misc ' + 'changes']
for path in Path('acpw').rglob('*'):
    if path.is_file():
        content = path.read_text(encoding='utf-8', errors='ignore')
        for pattern in patterns:
            if pattern.lower() in content.lower():
                print(f'{path}: forbidden placeholder marker {pattern}')
PY2
```

Expected: no matches in shipped ACPW content.

- [ ] **Step 5: Confirm no external runtime dependency was introduced**

Run:

```bash
python - <<'PY'
from pathlib import Path
text = Path('acpw/scripts/validate_package.py').read_text(encoding='utf-8')
for forbidden in ['yaml', 'requests', 'pydantic', 'click']:
    assert f'import {forbidden}' not in text
print('stdlib-only validator confirmed')
PY
```

Expected: `stdlib-only validator confirmed`.

- [ ] **Step 6: Review git diff and confirm only ACPW package/spec/plan changes are present**

```bash
git status --short
git diff --check
```

Expected: no whitespace errors; no unrelated changes included.

- [ ] **Step 7: Create the release commit**

```bash
git add acpw docs/superpowers/specs/2026-09-05-acpw-design.md docs/superpowers/plans/2026-09-05-acpw-package.md
git commit -m "feat(acpw): release adaptive Codex project workflow v1.0"
```

- [ ] **Step 8: Recommend, but do not create without project-owner approval, the release tag**

Recommended tag:

```text
acpw-v1.0.0
```

The implementation executor must stop for approval before creating or pushing the tag if repository policy requires human release approval.

---

## Plan Self-Review Result

- **Spec coverage:** Every approved design area maps to at least one concrete policy, template, prompt, validator rule, test, or rollout artifact.
- **Placeholder scan:** No unresolved placeholder markers or undefined implementation steps remain in this plan.
- **Interface consistency:** Governance level names, risk weights, thresholds, policy precedence, template field names, validator function names, and required prompt phrases are consistent across tasks.
- **Scope control:** The plan intentionally does not add a project installer, UI, service, database, or external dependency; ACPW remains a portable policy-and-template kit.
- **Testability:** Each task ends with an independently reviewable, testable deliverable and a commit boundary.
