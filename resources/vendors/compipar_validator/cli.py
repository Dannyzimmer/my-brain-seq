from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Sequence
from pathlib import Path

from ._version import __version__
from .engine import validate_values
from .parameters import ParametersFileError, parse_parameters
from .repository import MetadataFileError, load_metadata
from .result import ValidationResult


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="compipar-validate",
        description="Validate compi.parameters against parameters.metadata.json.",
    )
    parser.add_argument(
        "--metadata",
        required=True,
        type=Path,
        help="Path to parameters.metadata.json.",
    )
    parser.add_argument(
        "--params",
        required=True,
        type=Path,
        help="Path to compi.parameters.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        dest="json_output",
        help="Write a machine-readable result to stdout.",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Do not print non-strict warnings.",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        document = load_metadata(args.metadata, missing_ok=False)
        values = parse_parameters(args.params)
    except (MetadataFileError, ParametersFileError) as exc:
        return _input_error(str(exc), json_output=bool(args.json_output))
    try:
        result = validate_values(values, document)
    except Exception as exc:  # pragma: no cover - defensive CLI boundary
        if args.json_output:
            print(
                json.dumps(
                    {"valid": False, "error": str(exc)},
                    ensure_ascii=False,
                )
            )
        else:
            print(f"ERROR: {exc}", file=sys.stderr)
        return 3
    if args.json_output:
        print(json.dumps(result.to_dict(), indent=2, ensure_ascii=False))
    else:
        _print_human(result, quiet=bool(args.quiet))
    return 0 if result.valid else 1


def _input_error(message: str, *, json_output: bool) -> int:
    if json_output:
        print(
            json.dumps(
                {"valid": False, "error": message},
                ensure_ascii=False,
            )
        )
    else:
        print(f"ERROR: {message}", file=sys.stderr)
    return 2


def _print_human(result: ValidationResult, *, quiet: bool) -> None:
    if not quiet:
        for issue in result.metadata_issues:
            print(f"WARNING: {issue.message}", file=sys.stderr)
        for violation in result.warnings:
            print(
                f"WARNING [{violation.constraint_id}]: {violation.message}",
                file=sys.stderr,
            )
    for violation in result.strict_violations:
        print(
            f"ERROR [{violation.constraint_id}]: {violation.message}",
            file=sys.stderr,
        )
    if result.valid:
        print("Validation passed.", file=sys.stderr)

