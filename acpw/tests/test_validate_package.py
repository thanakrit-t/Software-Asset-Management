import tempfile
import unittest
import json
from pathlib import Path

from acpw.scripts.validate_package import (
    REQUIRED_FILES,
    load_json,
    main,
    required_files_missing,
    validate_global_policy,
    validate_project_policy,
)


class PackageCompletenessTests(unittest.TestCase):
    def test_empty_package_reports_every_required_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            missing = required_files_missing(Path(tmp))
            self.assertEqual(sorted(missing), sorted(REQUIRED_FILES))

    def test_cli_returns_one_for_incomplete_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(main([tmp]), 1)

    def test_cli_returns_zero_for_complete_package(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for relative_path in REQUIRED_FILES:
                target = root / relative_path
                target.parent.mkdir(parents=True, exist_ok=True)
                target.touch()
            self.assertEqual(main([tmp]), 0)


class PolicyTests(unittest.TestCase):
    def test_global_policy_has_no_invariant_errors(self):
        policy = load_json(Path("acpw/policy/global-baseline.json"))
        self.assertEqual(validate_global_policy(policy), [])

    def test_global_policy_rejects_wrong_weight_distribution_even_when_sum_is_100(self):
        policy = {
            "governance_order": ["Lightweight", "Standard", "Enterprise"],
            "risk_weights": {"architecture": 20, "security": 25, "data": 25, "delivery": 20, "operations": 10},
            "thresholds": {"Lightweight": [0, 29], "Standard": [30, 64], "Enterprise": [65, 100]},
            "hard_rules": {}, "full_repository_scan_default": False,
        }
        self.assertTrue(validate_global_policy(policy))

    def test_project_policy_may_raise_but_not_lower_a_hard_rule(self):
        global_policy = {"governance_order": ["Lightweight", "Standard", "Enterprise"], "hard_rules": {"prod_deploy": "Standard"}}
        raised = {"hard_rules": {"prod_deploy": "Enterprise"}}
        lowered = {"hard_rules": {"prod_deploy": "Lightweight"}}
        self.assertEqual(validate_project_policy(global_policy, raised), [])
        self.assertTrue(validate_project_policy(global_policy, lowered))

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

TEMPLATE_REQUIREMENTS = {
    "task.md": ["# Task ID", "# Goal", "# In Scope", "# Out of Scope", "# Acceptance Criteria", "# Execution Budget", "# Stop Conditions"],
    "checkpoint.md": ["# Project", "# Task ID", "# Current State", "# Tests Performed", "# Next Task", "# Do Not Re-read", "# Rollback Point"],
    "risk-assessment.md": ["# Hard Rule Check", "# Weighted Risk Score", "# Final Governance Level", "# Reasoning Level"],
    "change-standard.md": ["# Scope", "# Rollback Note", "# Release / Deployment Approval"],
    "change-enterprise.md": ["# Risk Assessment", "# Impact Assessment", "# Rollback Plan", "# Pre-Deployment Approval", "# Post-Change Verification"],
}


class ExecutionTemplateTests(unittest.TestCase):
    def test_execution_templates_contain_required_sections(self):
        for filename, headings in TEMPLATE_REQUIREMENTS.items():
            with self.subTest(filename=filename):
                self.assertEqual(required_headings_missing(Path("acpw/templates") / filename, headings), [])
if __name__ == "__main__":
    unittest.main()

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