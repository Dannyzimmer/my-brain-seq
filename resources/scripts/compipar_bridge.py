#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--params", required=True)
    return parser.parse_args()


def emit(level: str, identifier: str, message: str) -> None:
    clean_id = " ".join(str(identifier).split())
    clean_message = " ".join(str(message).split())
    print(f"{level}\t{clean_id}\t{clean_message}")


def main() -> int:
    args = parse_args()

    try:
        from compipar_validator import (
            MetadataFileError,
            ParametersFileError,
            load_metadata,
            parse_parameters,
            validate_values,
        )
    except Exception as exc:
        emit("ERROR", "validator", f"Could not import compipar_validator: {exc}")
        return 0

    metadata_path = Path(args.metadata)
    params_path = Path(args.params)

    if not metadata_path.is_file():
        emit(
            "WARNING",
            "metadata",
            f"Metadata file not found: {metadata_path}. Validation skipped.",
        )
        return 0

    if not params_path.is_file():
        emit("ERROR", "parameters", f"Parameters file not found: {params_path}.")
        return 0

    try:
        document = load_metadata(metadata_path, missing_ok=False)
        values = parse_parameters(params_path)
    except MetadataFileError as exc:
        emit("ERROR", "metadata", str(exc))
        return 0
    except ParametersFileError as exc:
        emit("ERROR", "parameters", str(exc))
        return 0
    except Exception as exc:
        emit("ERROR", "validator", f"Unexpected input error: {exc}")
        return 0

    try:
        result = validate_values(values, document)
    except Exception as exc:
        emit("ERROR", "validator", f"Unexpected validation error: {exc}")
        return 0

    for issue in result.metadata_issues:
        emit("WARNING", issue.context or "metadata", issue.message)

    for violation in result.violations:
        level = "ERROR" if violation.strict else "WARNING"
        emit(level, violation.constraint_id, violation.message)

    return 0


if __name__ == "__main__":
    sys.exit(main())
