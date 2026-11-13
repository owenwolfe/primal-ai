"""Deterministic preference matching, deliberately separate from HTTP and nutrition claims."""

import json
import re
import unicodedata
from pathlib import Path

RULES = json.loads(Path(__file__).with_name("rules.json").read_text())


def normalize(text):
    return " ".join(unicodedata.normalize("NFKC", text).casefold().split()).strip(" .")


INDEX = {}
for rule in RULES["ingredients"]:
    for alias in [rule["name"], *rule["aliases"]]:
        key = normalize(alias)
        if key in INDEX:
            raise RuntimeError(f"Duplicate ingredient alias: {key}")
        INDEX[key] = rule


def split_ingredients(text):
    text = unicodedata.normalize("NFKC", text).strip()
    text = re.sub(r"^ingredients?\s*:\s*", "", text, flags=re.I)
    # Allergen statements are not ingredient lists. Preserve 'contains 2%...' declarations.
    text = re.split(r"(?:\n|[.;])\s*(?:contains\s*:\s*|may contain\b)", text, flags=re.I)[0]
    if re.search(r"\bnutrition facts\b|\bcalories\b|\bdaily value\b", text, flags=re.I):
        raise ValueError("Keep only the ingredient list; remove nutrition facts before evaluating.")
    brackets = []
    items = []
    start = 0
    for position, char in enumerate(text):
        if char in "([":
            brackets.append(char)
        elif char in ")]":
            if not brackets or brackets.pop() != {")": "(", "]": "["}[char]:
                raise ValueError("An ingredient has unmatched brackets. Check the recognized text.")
        elif char in ",;\n" and not brackets:
            items.append(text[start:position].strip(" ."))
            start = position + 1
    if brackets:
        raise ValueError("An ingredient has unmatched brackets. Check the recognized text.")
    items.append(text[start:].strip(" ."))
    items = [item for item in items if item]
    if not items or len(items) > 100:
        raise ValueError("Provide between 1 and 100 ingredients.")
    return items


def evaluate(text):
    findings = []
    for position, item in enumerate(split_ingredients(text)):
        # Exact aliases only. Compound ingredients stay unknown until explicitly supported.
        rule = INDEX.get(normalize(item))
        group = rule["group"] if rule else "unknown"
        findings.append(
            {
                "id": str(position),
                "label": item,
                "name": rule["name"] if rule else item,
                "category": group,
                "explanation": RULES["categories"][group]["explanation"],
                "basis": "preference" if rule else "unmatched",
            }
        )
    unknown = [item["label"] for item in findings if item["category"] == "unknown"]
    status = "partial" if unknown else "complete"
    if len(unknown) == len(findings):
        status = "unrecognized"
    rating = None
    if status == "complete":
        review = any(item["category"] in {"added_sweetener", "additive"} for item in findings)
        rating = "review" if review else "aligned"
    return {
        "schemaVersion": "1",
        "rulesVersion": RULES["version"],
        "status": status,
        "rating": rating,
        "findings": findings,
        "unmatchedIngredients": unknown,
        "notice": RULES["notice"],
        "methodology": RULES["methodology"],
    }
