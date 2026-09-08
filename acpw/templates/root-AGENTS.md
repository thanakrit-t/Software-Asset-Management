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
