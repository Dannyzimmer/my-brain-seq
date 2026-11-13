from __future__ import annotations

from collections.abc import Mapping
from pathlib import Path

from .metadata import ParameterMetadata, ParameterMetadataDocument
from .parameters import parse_parameters
from .repository import load_metadata
from .result import ValidationResult
from .validation import (
    ConstraintViolation,
    evaluate_constraints,
    is_parameter_active,
)


def evaluate_parameter_requirements(
    values: Mapping[str, str | bool],
    parameters: Mapping[str, ParameterMetadata],
) -> list[ConstraintViolation]:
    violations: list[ConstraintViolation] = []
    for name, metadata in parameters.items():
        if metadata.required_value and not is_parameter_active(values, name):
            violations.append(
                ConstraintViolation(
                    f"parameter:{name}",
                    f"Parameter '{name}' must be active.",
                    metadata.strict,
                )
            )
    return violations


def validate_values(
    values: Mapping[str, str | bool],
    document: ParameterMetadataDocument,
) -> ValidationResult:
    violations = [
        *evaluate_parameter_requirements(values, document.parameters),
        *evaluate_constraints(values, document.validations),
    ]
    return ValidationResult(
        violations=tuple(violations),
        metadata_issues=document.metadata_issues,
    )


def validate_files(
    metadata_path: Path,
    parameters_path: Path,
) -> ValidationResult:
    document = load_metadata(metadata_path, missing_ok=True)
    values = parse_parameters(parameters_path)
    return validate_values(values, document)
