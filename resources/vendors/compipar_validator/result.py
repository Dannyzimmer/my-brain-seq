from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from .validation import ConstraintViolation


@dataclass(frozen=True)
class MetadataIssue:
    message: str
    context: str | None = None

    def to_dict(self) -> dict[str, Any]:
        data: dict[str, Any] = {"message": self.message}
        if self.context:
            data["context"] = self.context
        return data


@dataclass(frozen=True)
class ValidationResult:
    violations: tuple[ConstraintViolation, ...] = field(default_factory=tuple)
    metadata_issues: tuple[MetadataIssue, ...] = field(default_factory=tuple)

    @property
    def warnings(self) -> tuple[ConstraintViolation, ...]:
        return tuple(item for item in self.violations if not item.strict)

    @property
    def strict_violations(self) -> tuple[ConstraintViolation, ...]:
        return tuple(item for item in self.violations if item.strict)

    @property
    def valid(self) -> bool:
        return not self.strict_violations

    @property
    def has_warnings(self) -> bool:
        return bool(self.warnings or self.metadata_issues)

    def to_dict(self) -> dict[str, Any]:
        return {
            "valid": self.valid,
            "violations": [item.to_dict() for item in self.violations],
            "metadata_issues": [item.to_dict() for item in self.metadata_issues],
        }
