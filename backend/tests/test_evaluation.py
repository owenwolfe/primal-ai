import pytest

from primal.evaluation import evaluate, split_ingredients


def test_whole_food_aliases_and_culinary_ingredients_align():
    result = evaluate("Ingredients: Rolled Oats, almonds, Sea Salt.")
    assert result["rating"] == "aligned"
    assert result["status"] == "complete"
    assert result["findings"][0]["name"] == "oats"


@pytest.mark.parametrize("ingredient", ["honey", "sugar", "natural flavors", "xanthan gum"])
def test_review_is_preference_not_health_claim(ingredient):
    result = evaluate(f"oats, {ingredient}")
    assert result["rating"] == "review"
    assert result["findings"][1]["basis"] == "preference"
    assert "not a health" in result["notice"]


@pytest.mark.parametrize("text", ["oats, sugarr", "oats, peanut butter (peanuts, sugar)"])
def test_unknown_or_compound_ingredients_prevent_overall_rating(text):
    result = evaluate(text)
    assert result["rating"] is None
    assert result["status"] == "partial"
    assert len(result["unmatchedIngredients"]) == 1


def test_no_substring_or_long_name_guessing():
    result = evaluate("unsweetened almond beverage, sugarfree")
    assert result["status"] == "unrecognized"
    assert result["rating"] is None


def test_nested_groups_and_line_breaks():
    assert split_ingredients("oats\nsauce (tomatoes, spices (salt, pepper)), milk") == [
        "oats",
        "sauce (tomatoes, spices (salt, pepper))",
        "milk",
    ]


@pytest.mark.parametrize("text", ["oats (", "oats)", "oats ([)]", "", ",,,", "oats, " * 101])
def test_malformed_labels_are_rejected(text):
    with pytest.raises(ValueError):
        evaluate(text)


def test_allergen_statement_is_not_scored_as_an_ingredient():
    result = evaluate("Ingredients: oats, almonds. Contains: almonds.")
    assert result["rating"] == "aligned"
    assert len(result["findings"]) == 2


def test_nutrition_panel_must_be_removed():
    with pytest.raises(ValueError, match="nutrition facts"):
        evaluate("Nutrition Facts\nCalories 200\nIngredients: oats")
