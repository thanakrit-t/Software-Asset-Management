# Adaptive Codex Project Workflow (ACPW) — Design Specification

**Version:** 1.0  
**Date:** 2026-09-05  
**Status:** Written Spec Approved / Ready for Implementation

## 1. Purpose

ACPW is a reusable governance and execution workflow for any project that can benefit from Codex, including software development, infrastructure, networking, security, cloud, DevOps, migration, automation, troubleshooting, research/PoC, legacy systems, testing, documentation, deployment, and operations.

The design optimizes five outcomes:

1. Reduce unnecessary Codex usage caused by repeated repository discovery, oversized context, excessive reasoning, and unbounded retries.
2. Match governance rigor to operational risk rather than applying one process to all tasks.
3. Match reasoning effort to problem complexity rather than to production risk alone.
4. Preserve human control over risky or irreversible changes through adaptive approval gates.
5. Make work resumable across sessions through structured checkpoints and layered project context.

## 2. Scope

### 2.1 In scope

- New projects and existing projects
- Software, infrastructure, cloud, network, security, database, CI/CD, migration, automation, troubleshooting, PoC, documentation, deployment, and operations
- Local, development, staging, pre-production, and production environments
- Single-agent and parallel-agent workflows
- Human approval, risk classification, testing, evidence, rollback, and closeout
- Reusable templates for project and task-level execution

### 2.2 Out of scope

- Replacing organization-specific change-management policies
- Replacing formal regulatory or compliance controls
- Automatically bypassing human approval for risky production actions
- Treating chat history as the permanent source of project state

Organization- or project-specific controls may be stricter than ACPW. They must never weaken the Global Baseline.

## 3. Core Principles

1. **Adaptive governance:** Lightweight, Standard, or Enterprise depending on risk.
2. **Hybrid classification:** Codex assesses; the human may approve or override upward. Downward overrides may not cross the Safety Floor.
3. **Global Baseline + Project Policy:** project rules may increase rigor but may not reduce the global minimum.
4. **Risk and reasoning are separate:** governance measures consequence; reasoning measures cognitive difficulty.
5. **Progressive context loading:** load only the context required for the current task.
6. **Adaptive task slicing:** task size depends on scope, dependency, context, and risk.
7. **Bounded execution:** every task has explicit budget and stop conditions.
8. **Progressive verification:** cheap/fast checks precede expensive/full checks.
9. **Structured handoff:** state is persisted in checkpoints, not rediscovered from chat history.
10. **Evidence proportional to risk:** documentation depth increases with governance level.
11. **Isolation proportional to risk:** branch/worktree/environment isolation increases with risk.
12. **Parallelize independent execution, not duplicated thinking.**

## 4. Master Workflow

```text
NEW REQUEST
    ↓
Project / Task Intake
    ↓
Hard Rule Check
    ↓
Weighted Risk Score
    ↓
Governance Level
    ↓
Reasoning Routing
    ↓
Load Minimum Required Context
    ↓
Adaptive Task Slicing
    ↓
Execution Plan
    ↓
Human Approval Gate
    ↓
Work Isolation
    ↓
Implement / Execute
    ↓
Progressive Verification
    ↓
Review
    ↓
Checkpoint + Evidence
    ↓
Commit / Release Gate
    ↓
Deploy / Apply Change
    ↓
Post-Change Verification
    ↓
Closeout
    ↓
READY FOR NEXT TASK
```

## 5. Task Intake

Before execution, ACPW must establish the following where relevant:

```text
Goal
Project
Environment
Target system/module
Current state
Expected result
In scope
Out of scope
Production involved?
Security involved?
Data involved?
Destructive operation?
Rollback possible?
Dependencies
Acceptance criteria
```

Codex should infer safely obtainable information from the project before asking the user. The rule is:

> Inspect first; ask only what cannot be determined safely.

## 6. Governance Classification

### 6.1 Hard Rules first

Hard Rules are evaluated before the weighted risk score. If a Hard Rule defines a minimum governance level, that minimum cannot be reduced by the risk score or by user override.

### 6.2 Weighted Risk Score

Each factor is scored from 0–5, then normalized to 100 using these weights:

| Factor | Weight |
|---|---:|
| Security Risk | 25% |
| Data / Production Risk | 25% |
| Blast Radius | 20% |
| Reversibility | 15% |
| Business / Operational Impact | 10% |
| Complexity | 5% |

### 6.3 Thresholds

| Score | Governance |
|---:|---|
| 0–29 | Lightweight |
| 30–64 | Standard |
| 65–100 | Enterprise |

### 6.4 Final level rule

```text
Final Governance Level = MAX(
  Risk Score Level,
  Global Hard Rule Minimum,
  Project Policy Minimum
)
```

## 7. Global Hard Rule Catalog

### 7.1 Enterprise minimum

At minimum, the following are Enterprise:

- Production database schema migration
- DROP / TRUNCATE / destructive mass data modification
- Production data restore
- Disaster recovery or failover
- Core firewall, routing, or critical VPN gateway changes
- Root/admin/privileged IAM changes
- Private key or encryption key rotation
- Production CI/CD control-plane changes
- Critical filesystem/storage changes
- Production secrets migration
- Irreversible production operations

### 7.2 Standard minimum

At minimum, the following are Standard:

- Normal production application deployment
- Production configuration change
- Non-core firewall rule change
- Normal user permission change
- Certificate renewal
- Backup policy/configuration change
- Normal OS/server configuration change
- Standard CI/CD modification
- DNS / load balancer / reverse proxy modification

Project policy may raise any of these levels.

## 8. Governance-Level Workflows

### 8.1 Lightweight

```text
Assess
→ Short Plan
→ Human Approval
→ Execute
→ Targeted Verification
→ Commit
→ Checkpoint
```

Typical use: isolated low-risk changes, documentation, formatting, minor non-production configuration, small deterministic code changes.

### 8.2 Standard

```text
Assess
→ Scope + Plan
→ Approve Plan
→ Dedicated Branch / Task Isolation
→ Implement
→ Progressive Verification
→ Review
→ Release / Deployment Approval
→ Deploy
→ Verify
→ Checkpoint + Evidence
```

### 8.3 Enterprise

```text
Assess
→ Detailed Design / Change Plan
→ Risk + Impact Analysis
→ Rollback Plan
→ Approve Design / Change Plan
→ Isolated Worktree / Environment
→ Implement
→ Full Required Verification
→ Security / Data Review when applicable
→ Pre-Deployment Approval
→ Deploy / Apply Change
→ Post-Deployment Verification
→ Audit Evidence
→ Closeout
```

## 9. Reasoning Routing

Governance and reasoning are independent dimensions.

```text
Governance = consequence if wrong
Reasoning  = difficulty of solving correctly
```

### 9.1 Low reasoning

Use for known, repetitive, deterministic work such as documentation, formatting, known configuration changes, and small isolated edits.

### 9.2 Medium reasoning

Use for normal features, API implementation, typical debugging, query development, module refactors, and routine automation.

### 9.3 High reasoning

Use for architecture, unknown root cause, complex debugging, security analysis, migration design, cross-system failures, race conditions, and difficult performance analysis.

### 9.4 Escalation rule

Start with the lowest sufficient reasoning. Escalate only when evidence indicates unresolved ambiguity, competing hypotheses, architecture conflicts, cross-system dependencies, or new security implications.

## 10. Layered Context Architecture

Recommended project structure:

```text
project/
├── AGENTS.md
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── runbooks/
│   ├── changes/
│   ├── evidence/
│   ├── releases/
│   └── checkpoints/
│       └── current.md
├── backend/
│   └── AGENTS.md
├── frontend/
│   └── AGENTS.md
├── database/
│   └── AGENTS.md
├── infrastructure/
│   └── AGENTS.md
└── security/
    └── AGENTS.md
```

Session context loading order:

1. Root `AGENTS.md`
2. Relevant module `AGENTS.md`
3. `docs/checkpoints/current.md`
4. Only files required for the current task
5. Additional documents only when required

Full-repository scanning is not the default and must be justified.

## 11. Adaptive Task Slicing

Task size depends on scope, dependencies, context volume, and risk.

```text
Simple change
→ 1 task

Medium feature
→ 2–5 tasks

Large feature
→ Module
   └── Tasks

Enterprise / Cross-System
→ Phase
   └── Module
       └── Task
```

Each task must define:

```text
Task ID
Goal
Scope
Out of Scope
Required Context
Dependencies
Files / Systems
Acceptance Criteria
Verification
Risk
Budget
Stop Conditions
```

A task must be independently understandable, reviewable, and testable where technically possible.

## 12. Adaptive Execution Budget

### 12.1 Lightweight

- Targeted exploration only
- No full-repository scan by default
- 1–2 debugging iterations before stop/re-plan
- No architecture change without reclassification
- No uncontrolled dependency additions

### 12.2 Standard

- Targeted module exploration
- Limited retries based on evidence
- Cross-module expansion requires re-plan
- New dependency requires justification
- Root-cause changes trigger checkpoint and reassessment

### 12.3 Enterprise

- Follow the approved scope and change plan
- Use explicit checkpoints
- No unapproved production action
- Stop on material scope/risk change
- Preserve rollback viability throughout execution

## 13. Universal Stop Conditions

Codex must stop, summarize, and request re-planning or approval when any of the following occurs:

- Scope expands unexpectedly
- Architecture must change materially
- New security or data-loss risk is discovered
- A destructive action becomes necessary
- A production action is not approved
- Root cause differs materially from the approved plan
- Tests repeatedly fail beyond the execution budget
- A major new dependency is required
- Unknown uncommitted changes are detected
- Context becomes too broad for the task
- Rollback becomes invalid or unavailable
- Unexpected credentials, secrets, or sensitive material are encountered

Stop report format:

```text
STOP REASON
Current Findings
Impact
Options
Recommended Action
Additional Context Required
```

## 14. Adaptive Parallelism

Parallel execution is allowed only when all relevant conditions are true:

- Tasks are independent
- No shared mutable state
- No overlapping files or configuration targets
- Interfaces are already defined
- Inputs and outputs are clear
- Merge/integration path is known

Sequential execution is required when:

- Task B depends on Task A
- Tasks modify the same files/modules/state
- Architecture is not finalized
- Root cause is still unknown
- Production operations require ordered verification
- Shared database state creates coupling

Enterprise work may parallelize analysis, testing, or evidence collection when independent, but the actual production change path remains ordered and approval-gated.

## 15. Adaptive Isolation

### Lightweight

- Existing feature branch is acceptable
- Small atomic commit

### Standard

- Dedicated task or feature branch
- Baseline commit identified
- Task-level commits

### Enterprise

- Dedicated branch
- Isolated worktree or environment where practical
- Approved baseline commit
- Explicit rollback point
- Controlled merge or release path

Codex must not discard unrelated user work, hard-reset a working tree, delete unknown changes, or overwrite unrelated files without explicit authorization.

## 16. Adaptive Verification Pyramid

Verification proceeds from cheap/fast checks to broad/expensive checks.

```text
Change
→ Syntax / Config Validation
→ Static Analysis
→ Targeted / Unit Test
→ Module Test
→ Integration Test
→ Impacted Regression
→ Full Regression / Staging / Deployment Validation as required
```

### Lightweight

- Syntax / lint / config validation
- Targeted test
- Relevant smoke check

### Standard

- Syntax / lint
- Static analysis where available
- Unit / targeted tests
- Related integration tests
- Impacted regression checks

### Enterprise

- Static analysis
- Unit tests
- Integration tests
- Security/data validation where relevant
- Staging/pre-production validation where available
- Regression testing
- Deployment verification
- Post-change health checks

The workflow must not run expensive test layers when a cheaper prerequisite is already failing.

## 17. Failure Escalation Loop

Debugging must be hypothesis-driven rather than random repeated edits.

```text
Failure
→ Collect Evidence
→ Form Hypothesis
→ Test Hypothesis
→ Confirm / Reject
→ Fix or Form New Hypothesis
→ Check Retry Budget
→ Continue or STOP + Re-plan
```

## 18. Structured Checkpoint Standard

`docs/checkpoints/current.md` is the primary handoff artifact.

Required fields:

```text
Project
Phase
Module
Task ID
Governance Level
Reasoning Level
Status
Goal
Completed
Current State
Decisions
Files / Systems Changed
Tests Performed
Test Results
Known Issues
Risks
Open Questions
Next Task
Required Context
Do Not Re-read
Branch
Last Commit
Rollback Point
```

A new session should normally read only the root policy, relevant module policy, current checkpoint, and directly relevant files.

## 19. Adaptive Evidence Pack

### Lightweight

- Short change summary
- Tests performed / result
- Commit reference
- Checkpoint update

### Standard

- Change summary
- Components/files/systems changed
- Important decisions
- Test evidence
- Known limitations
- Rollback note
- Commit reference
- Checkpoint update

### Enterprise

- Approved change plan
- Risk assessment
- Impact assessment
- Implementation record
- Test evidence
- Security/data evidence when applicable
- Rollback procedure
- Rollback verification
- Deployment record
- Post-change validation
- Decision / exception records
- Audit-ready closeout

## 20. Single Source of Truth

Recommended locations:

```text
Architecture       → docs/architecture/
Decisions          → docs/decisions/
Current Status     → docs/checkpoints/current.md
Operational SOPs   → docs/runbooks/
Change Plans       → docs/changes/
Verification       → docs/evidence/
Release Records    → docs/releases/
```

Other documents should reference these sources instead of duplicating large blocks of information.

## 21. Commit Strategy

Use atomic, logical commits. One logical change should map to one logical commit wherever practical.

Examples:

```text
feat(auth): implement password policy
fix(ticket): prevent duplicate assignment
test(auth): add password policy tests
docs(runbook): add database rollback procedure
```

Avoid ambiguous commit messages such as `misc`, `update`, `fix stuff`, or `final`.

## 22. Definition of Done

A task is complete only when all applicable conditions are met:

- Goal achieved
- Acceptance criteria passed
- Scope did not unintentionally expand
- Relevant verification passed
- Security/data risks reviewed as required
- No unexplained failures remain
- Documentation/evidence appropriate to level is updated
- Checkpoint is updated
- Commit or equivalent change record exists
- Rollback remains possible where required
- Exact next task is known if project work continues

## 23. Session Start Protocol

```text
1. Read root AGENTS.md
2. Read relevant module AGENTS.md
3. Read docs/checkpoints/current.md
4. Check branch/worktree/environment status
5. Inspect only required files/systems
6. Confirm current task and governance level
7. Continue execution
```

## 24. Session End Protocol

```text
1. Run required verification
2. Summarize changes
3. Record unresolved issues
4. Update checkpoint
5. Record last commit/change identifier
6. Record rollback point
7. Define exact next task
8. Stop
```

## 25. Ten Golden Usage Rules

1. Never scan the whole repository unless justified.
2. Load context progressively.
3. One task must have one clear goal.
4. Start with the lowest sufficient reasoning.
5. Test targeted before broad regression.
6. Stop when scope or root cause changes materially.
7. Never debug indefinitely.
8. Parallelize only independent work.
9. Persist state in checkpoints, not chat history.
10. Reuse project knowledge instead of rediscovering it.

## 26. Example Routing

### 26.1 Web feature

```text
Governance: Standard
Reasoning: Medium
Context: root + relevant module + checkpoint
Isolation: feature/task branch
Verification: targeted + integration + impacted regression
Evidence: Standard
```

### 26.2 Production firewall change

```text
Governance: Standard or Enterprise depending on core-network impact
Reasoning: Low/Medium unless troubleshooting is complex
Approval: required
Verification: config validation + connectivity + health checks
Rollback: known-good configuration
```

### 26.3 Unknown server issue

```text
Governance: Standard unless risk floor raises it
Reasoning: High
Execution: evidence → hypotheses → targeted diagnostics
Stop: retry budget or scope/risk change
```

### 26.4 Documentation-only task

```text
Governance: Lightweight
Reasoning: Low
Context: only relevant docs
Verification: content/links/format checks
Evidence: short summary + checkpoint
```

### 26.5 Production database migration

```text
Governance: Enterprise by Hard Rule
Reasoning: Medium/High depending on migration complexity
Required: design, backup/restore readiness, dry-run, rollback validation,
approval, migration, data validation, application validation, evidence, closeout
```

## 27. Configuration Precedence

The precedence order is:

```text
Organization / Legal / Regulatory Controls
        ↓
Global ACPW Baseline
        ↓
Project Policy
        ↓
Task-Specific Assessment
        ↓
Human Approval / Upward Override
```

No lower layer may weaken a higher-layer minimum.

## 28. Approved Design Decisions

The approved defaults are:

- Scope: all Codex-capable project types
- Governance: Adaptive
- Classification: Hybrid Codex + Human
- Safety Floor: Minimum Level enforced
- Policy Model: Global Baseline + Project Override
- Risk Model: Hybrid Hard Rules + Weighted Risk Score
- Risk Weights: Security 25%, Data/Production 25%, Blast Radius 20%, Reversibility 15%, Impact 10%, Complexity 5%
- Thresholds: 0–29 Lightweight, 30–64 Standard, 65–100 Enterprise
- Hard Rule Catalog: Standard Catalog
- Hard Rule Levels: Tiered Standard / Enterprise
- Approval Model: Adaptive Approval Gates
- Context: Layered Context
- Task Breakdown: Adaptive Task Slicing
- Execution Control: Adaptive Budget + Stop Conditions
- Handoff: Structured Checkpoint Artifact
- Isolation: Adaptive Isolation
- Verification: Adaptive Verification Pyramid
- Evidence: Adaptive Evidence Pack
- Reasoning: Adaptive Model / Reasoning Routing
- Parallelism: Adaptive Parallelism

## 29. Design Self-Review Result

- No unresolved TBD/TODO placeholders remain.
- Governance and reasoning are explicitly separated.
- Hard Rules override risk score and define a non-reducible Safety Floor.
- Project policy can only increase rigor, never reduce the Global Baseline.
- Enterprise actions remain approval-gated.
- Context, execution, verification, evidence, and handoff rules are internally consistent.
- The design is broad enough for all Codex-capable projects but narrow enough to be implemented as reusable policies, templates, and prompts.

## 30. Next Deliverable After User Review

After this written design specification is reviewed and approved, the implementation-planning phase will define the concrete reusable ACPW package, including:

- Root `AGENTS.md` template
- Module `AGENTS.md` template
- `checkpoint.md` template
- Risk assessment template
- Task specification template
- Standard and Enterprise change-plan templates
- Evidence pack templates
- Session start/end prompts
- Master Codex prompt / operating policy
- Suggested repository layout
- Rollout and adoption checklist
- Verification plan for the workflow itself

