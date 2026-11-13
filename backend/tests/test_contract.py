import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

from primal.evaluation import evaluate

SPEC = json.loads((Path(__file__).parents[2] / "contracts/openapi.json").read_text())


@pytest.mark.parametrize("text", ["oats, salt", "oats, sugar", "oats, mystery", "mystery"])
def test_evaluation_obeys_the_published_schema(text):
    schema = {"$ref": "#/components/schemas/Evaluation", "components": SPEC["components"]}
    Draft202012Validator.check_schema(schema)
    Draft202012Validator(schema).validate(evaluate(text))


def test_partial_rating_is_forbidden_by_the_contract():
    result = evaluate("oats, mystery")
    result["rating"] = "aligned"
    schema = {"$ref": "#/components/schemas/Evaluation", "components": SPEC["components"]}
    assert list(Draft202012Validator(schema).iter_errors(result))
