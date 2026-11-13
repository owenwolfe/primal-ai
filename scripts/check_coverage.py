"""Compare configured core modules using coverage.py or xccov JSON reports."""

import argparse
import json
from decimal import Decimal
from pathlib import Path
from typing import Any


def percentages(report: dict[str, Any], prefixes: list[str], kind: str) -> dict[str, Decimal]:
    if kind == "python":
        records = {
            name: Decimal(str(item["summary"]["percent_covered"])).quantize(Decimal("0.01"))
            for name, item in report["files"].items()
        }
    else:
        records = {
            "ios/" + item["path"].split("ios/", 1)[-1]: (
                Decimal(str(item["lineCoverage"])) * 100
            ).quantize(Decimal("0.01"))
            for target in report["targets"]
            for item in target["files"]
            if item["executableLines"] > 0
        }
    result = {
        name: value for name, value in records.items() if any(prefix in name for prefix in prefixes)
    }
    for prefix in prefixes:
        if not any(prefix in name for name in result):
            raise ValueError(f"Configured coverage module missing from report: {prefix}")
    return result


def compare(base: dict[str, Decimal], current: dict[str, Decimal]) -> list[str]:
    return [
        f"{name}: {value}% → {current.get(name, 'missing')}%"
        for name, value in base.items()
        if name not in current or current[name] < value
    ]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", type=Path)
    parser.add_argument("current", type=Path)
    parser.add_argument("--kind", choices=["python", "swift"], default="python")
    parser.add_argument("--base-policy", type=Path, default=Path("coverage-policy.json"))
    args = parser.parse_args()
    policy = json.loads(Path("coverage-policy.json").read_text())
    prefixes = policy[args.kind]
    base_prefixes = json.loads(args.base_policy.read_text())[args.kind]
    if not prefixes:
        if base_prefixes:
            raise SystemExit("Cannot remove existing core-module coverage protection.")
        print(
            "No product core modules exist yet; application coverage baseline is not established."
        )
        return
    current = percentages(json.loads(args.current.read_text()), prefixes, args.kind)
    if not base_prefixes:
        print("Initial core coverage report validated; this revision establishes the baseline.")
        return
    base = percentages(json.loads(args.base.read_text()), base_prefixes, args.kind)
    failures = compare(base, current)
    if failures:
        raise SystemExit("Coverage regression:\n" + "\n".join(failures))
    print("No core-module coverage regression.")


if __name__ == "__main__":
    main()
