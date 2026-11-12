"""Run local infrastructure checks; never start or deploy an application."""

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "check",
        choices=["all", "format", "lint", "types", "test", "audit"],
        default="all",
        nargs="?",
    )
    args = parser.parse_args()
    commands = {
        "format": [
            "ruff",
            "format",
            "--check",
            "--config",
            "backend/pyproject.toml",
            "scripts",
            "tests",
        ],
        "lint": ["ruff", "check", "--config", "backend/pyproject.toml", "scripts", "tests"],
        "types": [
            "mypy",
            "--config-file",
            "backend/pyproject.toml",
            "--cache-dir",
            "reports/mypy",
            "scripts",
            "tests/infrastructure",
        ],
        "test": [
            "pytest",
            "-c",
            "backend/pyproject.toml",
            "--rootdir=.",
            "tests/infrastructure",
            "--cov=scripts",
            "--cov-config=backend/pyproject.toml",
            "--cov-report=term-missing",
            "--cov-report=json:reports/coverage.json",
            "--cov-report=xml:reports/coverage.xml",
            "--junitxml=reports/pytest.xml",
        ],
        "audit": [
            "pip-audit",
            "--cache-dir",
            "reports/pip-audit-cache",
            "--disable-pip",
            "--no-deps",
            "-r",
            "reports/runtime-requirements.txt",
        ],
    }
    (ROOT / "reports").mkdir(exist_ok=True)
    selected = list(commands)[:-1] if args.check == "all" else [args.check]
    for name in selected:
        if name == "audit" and not (ROOT / "reports/runtime-requirements.txt").exists():
            parser.error("Export locked runtime requirements first; see README security commands.")
        print(f"\n=== {name} ===", flush=True)
        subprocess.run(commands[name], cwd=ROOT, check=True)


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as error:
        sys.exit(error.returncode)
