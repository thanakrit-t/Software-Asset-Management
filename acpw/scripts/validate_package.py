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
