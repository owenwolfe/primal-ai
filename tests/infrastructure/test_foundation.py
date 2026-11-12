"""Toolchain probes only: no product behavior, network calls, or database."""

import json
import subprocess
import tomllib
from decimal import Decimal
from pathlib import Path
from typing import Any

import django
import pytest
import yaml
from django.conf import settings

from scripts.check_coverage import compare, main, percentages

ROOT = Path(__file__).resolve().parents[2]


def test_django_without_database() -> None:
    if not settings.configured:
        settings.configure(INSTALLED_APPS=[], DATABASES={}, USE_TZ=True)
    django.setup()
    assert django.VERSION[:2] == (5, 2)
    assert settings.INSTALLED_APPS == []


def test_configuration_loads() -> None:
    manifest = tomllib.loads((ROOT / "backend/pyproject.toml").read_text())
    lock = tomllib.loads((ROOT / "backend/uv.lock").read_text())
    assert manifest["tool"]["uv"]["package"] is False
    # uv canonicalizes >=3.14,<3.15 to ==3.14.* in its lockfile.
    version = json.loads((ROOT / "toolchain.json").read_text())["python"]
    assert lock["requires-python"] == f"=={version}.*"
    assert json.loads((ROOT / ".swift-format").read_text())["version"] == 1
    assert json.loads((ROOT / "toolchain.json").read_text())["python"] == "3.14"


def test_workflow_permissions_and_pins() -> None:
    for path in (ROOT / ".github/workflows").glob("*.yml"):
        workflow = yaml.safe_load(path.read_text())
        assert workflow["permissions"] == {"contents": "read"}
        for job in workflow["jobs"].values():
            for step in job.get("steps", []):
                if "uses" in step:
                    ref = step["uses"].split("@")[-1]
                    assert len(ref) == 40, f"Action must be SHA pinned: {step['uses']}"


def test_compose_has_no_database_or_secret_file() -> None:
    compose = yaml.safe_load((ROOT / "compose.yaml").read_text())
    assert set(compose["services"]) == {"backend"}
    backend = compose["services"]["backend"]
    assert backend["read_only"] is True
    assert "env_file" not in backend
    assert backend["cap_drop"] == ["ALL"]


def python_report(value: float) -> dict[str, Any]:
    return {"files": {"core/rating.py": {"summary": {"percent_covered": value}}}}


def test_coverage_detects_regression_and_missing_modules() -> None:
    base = percentages(python_report(90.0), ["core/"], "python")
    current = percentages(python_report(89.99), ["core/"], "python")
    assert len(compare(base, current)) == 1
    assert compare(base, base) == []
    assert compare(base, {})
    with pytest.raises(ValueError, match="missing"):
        percentages(python_report(90), ["absent/"], "python")


def test_swift_coverage_normalization() -> None:
    report = {
        "targets": [
            {
                "files": [
                    {
                        "path": "ios/Core/Labels.swift",
                        "lineCoverage": 0.84565,
                        "executableLines": 10,
                    }
                ]
            }
        ]
    }
    assert percentages(report, ["Core/"], "swift") == {"ios/Core/Labels.swift": Decimal("84.56")}


def test_release_readiness_fails_before_external_actions() -> None:
    result = subprocess.run(  # noqa: S603 -- fixed local readiness probe, no deployment
        ["/bin/sh", str(ROOT / "scripts/release-prerequisites.sh")],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    assert result.returncode == 1
    assert "application implementation required" in result.stderr


def test_shell_scripts_parse() -> None:
    for path in (ROOT / "scripts").glob("*.sh"):
        subprocess.run(["/bin/bash", "-n", str(path)], check=True)  # noqa: S603 -- syntax only


@pytest.mark.parametrize(
    ("base_prefixes", "current_prefixes", "expected_error"),
    [
        ([], ["core/"], None),
        (["core/"], ["core/"], "Coverage regression"),
        (["core/"], [], "Cannot remove"),
    ],
)
def test_coverage_policy_transition(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    base_prefixes: list[str],
    current_prefixes: list[str],
    expected_error: str | None,
) -> None:
    for name, content in {
        "coverage-policy.json": {"python": current_prefixes},
        "base-policy.json": {"python": base_prefixes},
        "base.json": python_report(90),
        "current.json": python_report(80),
    }.items():
        (tmp_path / name).write_text(json.dumps(content))
    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(
        "sys.argv",
        ["check_coverage", "base.json", "current.json", "--base-policy", "base-policy.json"],
    )
    if expected_error:
        with pytest.raises(SystemExit, match=expected_error):
            main()
    else:
        main()
