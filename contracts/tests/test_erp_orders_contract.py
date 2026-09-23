import json
from pathlib import Path

import pytest
import yaml
from jsonschema import Draft7Validator, FormatChecker

CONTRACT_PATH = Path(__file__).resolve().parent.parent / "erp_orders.contract.yaml"
FIXTURES_DIR = Path(__file__).resolve().parent / "fixtures"


@pytest.fixture(scope="module")
def contract_spec():
    with open(CONTRACT_PATH, "r", encoding="utf-8") as f:
        spec = yaml.safe_load(f)
    assert spec["contract_version"] == "1.0.0"
    assert "schema" in spec
    return spec


@pytest.fixture(scope="module")
def schema_validator(contract_spec):
    schema = contract_spec["schema"]
    Draft7Validator.check_schema(schema)
    return Draft7Validator(schema, format_checker=FormatChecker())


def load_fixture(fixture_name: str) -> dict:
    with open(FIXTURES_DIR / fixture_name, "r", encoding="utf-8") as f:
        return json.load(f)


def test_contract_accepts_valid_payload(schema_validator):
    payload = load_fixture("valid_order.json")
    errors = list(schema_validator.iter_errors(payload))
    assert errors == [], f"Expected 0 errors, got: {[e.message for e in errors]}"


def test_contract_rejects_missing_required_field(schema_validator):
    payload = load_fixture("missing_required_field.json")
    errors = list(schema_validator.iter_errors(payload))
    messages = [e.message for e in errors]
    assert any("'customer_id' is a required property" in msg for msg in messages)


def test_contract_rejects_invalid_enum(schema_validator):
    payload = load_fixture("invalid_enum.json")
    errors = list(schema_validator.iter_errors(payload))
    failed_paths = [e.path[0] for e in errors if e.path]
    assert "order_status" in failed_paths
    assert any("DISPATCHED_NEW" in e.message for e in errors)


def test_contract_rejects_invalid_numeric_range(schema_validator):
    payload = load_fixture("invalid_numeric_range.json")
    errors = list(schema_validator.iter_errors(payload))
    failed_paths = [e.path[0] for e in errors if e.path]
    assert "order_total" in failed_paths
    assert any("less than the minimum of 0" in e.message for e in errors)


def test_contract_rejects_invalid_datetime_format(schema_validator):
    payload = load_fixture("invalid_datetime.json")
    errors = list(schema_validator.iter_errors(payload))
    failed_paths = [e.path[0] for e in errors if e.path]
    assert "order_timestamp" in failed_paths
    assert any("is not a 'date-time'" in e.message for e in errors)
