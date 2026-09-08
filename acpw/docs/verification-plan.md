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
