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
