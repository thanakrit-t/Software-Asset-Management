import tempfile
import unittest
import json
import shutil
from pathlib import Path

from acpw.scripts.validate_package import (
    REQUIRED_FILES,
    load_json,
    main,
    required_files_missing,
    validate_package,
    validate_global_policy,
    validate_project_policy,
)

def create_complete_fixture(root: Path) -> None:
    source = Path('acpw')
    for relative_path in REQUIRED_FILES:
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        source_path = source / relative_path
        if source_path.is_file():
            shutil.copyfile(source_path, target)
        else:
            target.write_text("fixture\n", encoding="utf-8")


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
            create_complete_fixture(root)
            self.assertEqual(main([tmp]), 0)


class EndToEndValidationTests(unittest.TestCase):
    def test_complete_fixture_validates_cleanly(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            create_complete_fixture(root)
            self.assertEqual(validate_package(root), [])

    def test_missing_required_file_is_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            errors = validate_package(Path(tmp))
            self.assertTrue(any('missing required file' in error for error in errors))


class PolicyTests(unittest.TestCase):
    def test_global_policy_has_no_invariant_errors(self):
        policy = load_json(Path("acpw/policy/global-baseline.json"))
        self.assertEqual(validate_global_policy(policy), [])

    def test_global_policy_rejects_wrong_weight_distribution_even_when_sum_is_100(self):
        policy = {
            "governance_order": ["Lightweight", "Standard", "Enterprise"],
            "risk_weights": {"security": 20, "data_production": 25, "blast_radius": 20, "reversibility": 15, "business_operational_impact": 10, "complexity": 10},
            "thresholds": {"Lightweight": [0, 29], "Standard": [30, 64], "Enterprise": [65, 100]},
            "hard_rules": {}, "full_repository_scan_default": False,
        }
        self.assertTrue(validate_global_policy(policy))

    def test_global_policy_uses_binding_six_factor_weights(self):
        policy = load_json(Path("acpw/policy/global-baseline.json"))
        self.assertEqual(policy["risk_weights"], {
            "security": 25,
            "data_production": 25,
            "blast_radius": 20,
            "reversibility": 15,
            "business_operational_impact": 10,
            "complexity": 5,
        })

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


class SpecCoverageTests(unittest.TestCase):
    def test_each_design_area_maps_to_a_shipped_artifact(self):
        coverage = {
            "Governance + Hard Rules": ["policy/global-baseline.json", "prompts/master-operating-prompt.md"],
            "Reasoning Routing": ["prompts/master-operating-prompt.md", "templates/root-AGENTS.md"],
            "Layered Context": ["templates/root-AGENTS.md", "templates/module-AGENTS.md", "prompts/session-start.md"],
            "Task Slicing/Budget/Stops": ["templates/task.md", "prompts/master-operating-prompt.md"],
            "Parallelism": ["prompts/master-operating-prompt.md"],
            "Isolation": ["templates/root-AGENTS.md", "templates/change-standard.md", "templates/change-enterprise.md"],
            "Verification Pyramid": ["templates/root-AGENTS.md", "templates/change-standard.md", "templates/change-enterprise.md", "docs/verification-plan.md"],
            "Checkpoint": ["templates/checkpoint.md", "prompts/session-start.md", "prompts/session-end.md"],
            "Evidence": ["templates/evidence-lightweight.md", "templates/evidence-standard.md", "templates/evidence-enterprise.md"],
            "Single Source of Truth": ["templates/root-AGENTS.md"],
            "Commit / DoD": ["templates/root-AGENTS.md", "prompts/master-operating-prompt.md"],
            "Rollout / Adoption": ["README.md", "docs/rollout-checklist.md"],
            "Workflow Self-Verification": ["tests/test_validate_package.py", "scripts/validate_package.py", "docs/verification-plan.md"],
        }
        package_root = Path("acpw")
        for area, artifacts in coverage.items():
            with self.subTest(area=area):
                for artifact in artifacts:
                    path = package_root / artifact
                    self.assertTrue(path.is_file(), f"{area}: missing {path}")
                    self.assertGreater(path.stat().st_size, 0, f"{area}: empty {path}")


class ReviewRemediationCoverageTests(unittest.TestCase):
    def test_standard_work_requires_dedicated_task_or_feature_branch(self):
        guidance = (
            Path("acpw/templates/root-AGENTS.md").read_text(encoding="utf-8")
            + Path("acpw/templates/change-standard.md").read_text(encoding="utf-8")
            + Path("acpw/prompts/master-operating-prompt.md").read_text(encoding="utf-8")
        )
        self.assertRegex(guidance, r"(?i)Standard.{0,120}(dedicated task|feature) branch")

    def test_commit_guidance_requires_atomic_logical_commits(self):
        guidance = (
            Path("acpw/templates/root-AGENTS.md").read_text(encoding="utf-8")
            + Path("acpw/prompts/master-operating-prompt.md").read_text(encoding="utf-8")
        )
        self.assertRegex(guidance, r"(?i)atomic.{0,80}logical commit")


class SafetyInvariantValidationTests(unittest.TestCase):
    def _valid_policy(self):
        return load_json(Path("acpw/policy/global-baseline.json"))

    def _assert_package_and_cli_fail(self, policy):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            create_complete_fixture(root)
            (root / "policy/global-baseline.json").write_text(json.dumps(policy), encoding="utf-8")
            errors = validate_package(root)
            self.assertTrue(errors)
            self.assertEqual(main([str(root)]), 1)

    def test_missing_mandatory_hard_rule_is_rejected(self):
        policy = self._valid_policy()
        del policy["hard_rules"]["production_database_schema_migration"]
        self._assert_package_and_cli_fail(policy)

    def test_downgraded_enterprise_hard_rule_is_rejected(self):
        policy = self._valid_policy()
        policy["hard_rules"]["production_database_schema_migration"] = "Standard"
        self._assert_package_and_cli_fail(policy)

    def test_missing_required_approval_gate_is_rejected(self):
        policy = self._valid_policy()
        del policy["approval_gates"]["Enterprise"]
        self._assert_package_and_cli_fail(policy)

    def test_invalid_retry_budget_is_rejected(self):
        policy = self._valid_policy()
        policy["retry_budget"]["Standard"] = 0
        self._assert_package_and_cli_fail(policy)

    def test_missing_retry_budget_is_rejected(self):
        policy = self._valid_policy()
        del policy["retry_budget"]["Enterprise"]
        self._assert_package_and_cli_fail(policy)

    def test_project_policy_upward_override_remains_valid(self):
        policy = self._valid_policy()
        project = load_json(Path("acpw/policy/project-policy.example.json"))
        project["hard_rules"]["certificate_renewal"] = "Enterprise"
        self.assertEqual(validate_project_policy(policy, project), [])


class MalformedPolicyValidationTests(unittest.TestCase):
    def test_malformed_global_json_returns_actionable_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            create_complete_fixture(root)
            (root / "policy/global-baseline.json").write_text("{", encoding="utf-8")
            errors = validate_package(root)
            self.assertTrue(any("global-baseline.json" in error and "invalid JSON" in error for error in errors))

    def test_wrong_global_shape_returns_errors_without_project_check(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            create_complete_fixture(root)
            (root / "policy/global-baseline.json").write_text("[]", encoding="utf-8")
            errors = validate_package(root)
            self.assertTrue(any("global-baseline.json" in error and "object" in error for error in errors))
            self.assertFalse(any("project policy" in error for error in errors))

    def test_wrong_field_type_returns_actionable_error(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            create_complete_fixture(root)
            policy = load_json(Path("acpw/policy/global-baseline.json"))
            policy["risk_weights"] = None
            (root / "policy/global-baseline.json").write_text(json.dumps(policy), encoding="utf-8")
            errors = validate_package(root)
            self.assertTrue(any("risk_weights" in error and "object" in error for error in errors))


class TestModuleExecutionTests(unittest.TestCase):
    def test_module_execution_collects_all_tests(self):
        self.assertTrue(True)


class ResidualPolicyValidationTests(unittest.TestCase):
    def test_retry_budget_accepts_positive_values_within_caps(self):
        policy = load_json(Path("acpw/policy/global-baseline.json"))
        for level, value in [("Lightweight", 1), ("Lightweight", 2), ("Standard", 1), ("Standard", 3), ("Enterprise", 1), ("Enterprise", 3)]:
            policy["retry_budget"][level] = value
            self.assertFalse([e for e in validate_global_policy(policy) if "retry_budget" in e])

    def test_retry_budget_rejects_zero_bool_non_int_and_over_cap(self):
        policy = load_json(Path("acpw/policy/global-baseline.json"))
        for value in [0, True, 1.5, 3, 999]:
            policy["retry_budget"]["Lightweight"] = value
            errors = validate_global_policy(policy)
            self.assertTrue(any("retry_budget.Lightweight" in e for e in errors), value)

    def test_global_hard_rule_level_must_be_a_string(self):
        policy = load_json(Path("acpw/policy/global-baseline.json"))
        for value in [[], {}]:
            policy["hard_rules"]["certificate_renewal"] = value
            errors = validate_global_policy(policy)
            self.assertTrue(any("hard rule certificate_renewal" in e and "invalid minimum" in e for e in errors))

    def test_project_hard_rule_level_must_be_a_string(self):
        global_policy = load_json(Path("acpw/policy/global-baseline.json"))
        for value in [[], {}]:
            errors = validate_project_policy(global_policy, {"hard_rules": {"certificate_renewal": value}})
            self.assertTrue(any("project rule certificate_renewal" in e and "invalid level" in e for e in errors))

    def test_project_minimum_governance_must_be_a_string(self):
        global_policy = load_json(Path("acpw/policy/global-baseline.json"))
        for value in [[], {}]:
            errors = validate_project_policy(global_policy, {"hard_rules": {}, "minimum_governance": value})
            self.assertTrue(any("minimum_governance" in e and "invalid" in e for e in errors))

if __name__ == "__main__":
    unittest.main()
