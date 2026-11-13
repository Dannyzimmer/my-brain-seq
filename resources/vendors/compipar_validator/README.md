# compipar-validator

Small, dependency-free validator for Compi test parameter files.

It reads `compi.parameters` and the optional
`parameters.metadata.json` file used by Compi pipelines, evaluates
cross-parameter validation rules, and reports warnings or strict errors.

The package has no GUI dependencies and can be used from Python or from the
`compipar-validate` command line.

## Installation

```bash
pip install .
```

For development:

```bash
pip install -e ".[dev]"
```

## Supported rules

The top-level `validations` array in `parameters.metadata.json` accepts:

```json
{
  "schema_version": 1,
  "parameters": {},
  "validations": [
    {
      "id": "one-of-input",
      "type": "exactly_one",
      "parameters": ["targetFasta", "targetDir"],
      "strict": true
    },
    {
      "id": "optional-mutual-exclusion",
      "type": "at_most_one",
      "parameters": ["modeA", "modeB"]
    },
    {
      "id": "custom-db",
      "type": "requires",
      "when": "useCustomDb",
      "require": ["dbPath", "dbVersion"],
      "message": "When useCustomDb is active, dbPath and dbVersion are required."
    },
    {"id": "any-input", "type": "at_least_one", "parameters": ["a", "b"]},
    {"id": "db-option", "type": "requires_any", "when": "custom", "require": ["path", "url"]},
    {"id": "no-local", "type": "forbids", "when": "container", "forbid": ["local"]},
    {"id": "db-group", "type": "all_or_none", "parameters": ["useDb", "dbPath"]}
  ]
}
```

Rule types:

- `exactly_one`: exactly one parameter in the group must be active.
- `at_most_one`: zero or one parameter in the group may be active.
- `at_least_one`: at least one parameter in the group must be active.
- `requires`: when `when` is active, every parameter in `require` must be
  active.
- `requires_any`: when `when` is active, at least one parameter in `require`
  must be active.
- `forbids`: when `when` is active, no parameter in `forbid` may be active.
- `all_or_none`: the group must be completely active or completely inactive.

### Required parameters

Per-parameter metadata supports `required_value`:

```json
"parameters": {
  "targetFasta": {
    "required_value": true,
    "strict": true
  }
}
```

A required parameter must be **active**, using the same definition as the
validation rules. The violation is reported as:

```text
Parameter 'targetFasta' must be active.
```

`strict` controls whether the violation blocks the caller or is only a warning.

### Empty/inactive values

A parameter is active when:

- it is a flag and it is present;
- or its value is non-empty and is not one of the following empty/false values:

```text
(empty)
0
0.0
FALSE
NO
OFF
NONE
NULL
NA
N/A
```

These values are treated as not declared. Do not use them to satisfy a
`required_value` or any rule that requires an active parameter.

Definitions are case-insensitive. Non-strict rules produce warnings. Strict
rules make the result invalid.

## Python API

```python
from pathlib import Path

from compipar_validator import validate_files

result = validate_files(
    Path("parameters.metadata.json"),
    Path("compi.parameters"),
)

if result.valid:
    print("Parameters are valid")
else:
    for violation in result.strict_violations:
        print(f"ERROR [{violation.constraint_id}]: {violation.message}")
```

Lower-level API:

```python
from compipar_validator import (
    evaluate_constraints,
    load_metadata,
    parse_parameters,
    validate_values,
)

document = load_metadata("parameters.metadata.json")
values = parse_parameters("compi.parameters")
result = validate_values(values, document)
```

`load_metadata` also exposes metadata problems through
`document.metadata_issues`. Invalid validation rules are reported and ignored;
the rest of the rules are still evaluated.

## CLI

```bash
compipar-validate \
  --metadata parameters.metadata.json \
  --params compi.parameters
```

Options:

```text
--metadata PATH   parameters.metadata.json
--params PATH     compi.parameters
--json            Machine-readable output on stdout
--quiet           Suppress non-strict warnings
--version         Show the package version
```

Exit codes:

| Code | Meaning |
|---:|---|
| 0 | Valid, or only non-strict warnings |
| 1 | At least one strict violation |
| 2 | Invalid inputs or arguments |
| 3 | Internal error |

Example JSON output:

```json
{
  "valid": false,
  "violations": [
    {
      "id": "one-of-input",
      "message": "Exactly one of these parameters must be active: targetFasta, targetDir.",
      "strict": true
    }
  ],
  "metadata_issues": []
}
```

## Development

```bash
ruff check src tests
mypy src
pytest
python -m build
```

## License

MIT
