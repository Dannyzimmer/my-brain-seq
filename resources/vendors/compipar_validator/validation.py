from __future__ import annotations

import uuid
from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Any

VALIDATION_TYPES = frozenset(
    {
        "exactly_one",
        "at_most_one",
        "at_least_one",
        "requires",
        "requires_any",
        "forbids",
        "all_or_none",
    }
)
_FALSE_VALUES = {
    "",
    "0",
    "0.0",
    "FALSE",
    "NO",
    "OFF",
    "NONE",
    "NULL",
    "NA",
    "N/A",
}
_CONSTRAINT_KEYS = {
    "id",
    "type",
    "parameters",
    "when",
    "require",
    "forbid",
    "message",
    "strict",
}


@dataclass(frozen=True)
class ParameterConstraint:
    id: str
    type: str
    parameters: tuple[str, ...] = ()
    when: str | None = None
    require: tuple[str, ...] = ()
    forbid: tuple[str, ...] = ()
    message: str | None = None
    strict: bool = False
    extra: Mapping[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: Any) -> ParameterConstraint | None:
        if not isinstance(data, Mapping):
            return None
        kind = str(data.get("type") or "").strip()
        if kind not in VALIDATION_TYPES:
            return None
        parameters = _names(data.get("parameters") or [])
        require = _names(data.get("require") or [])
        forbid = _names(data.get("forbid") or [])
        when = str(data.get("when") or "").strip() or None
        if kind in {"exactly_one", "at_most_one", "at_least_one"}:
            if len(parameters) < 2:
                return None
        elif kind == "all_or_none":
            if len(parameters) < 2:
                return None
        elif kind in {"requires", "requires_any"}:
            if not when or not require:
                return None
        elif kind == "forbids":
            if not when or not forbid:
                return None
        return cls(
            id=str(data.get("id") or uuid.uuid4().hex),
            type=kind,
            parameters=parameters,
            when=when,
            require=require,
            forbid=forbid,
            message=str(data["message"]) if data.get("message") else None,
            strict=bool(data.get("strict")),
            extra={
                key: value
                for key, value in data.items()
                if key not in _CONSTRAINT_KEYS
            },
        )

    def to_dict(self) -> dict[str, Any]:
        data = dict(self.extra)
        data.update(
            {
                "id": self.id,
                "type": self.type,
                "strict": self.strict,
            }
        )
        if self.type in {
            "exactly_one",
            "at_most_one",
            "at_least_one",
            "all_or_none",
        }:
            data["parameters"] = list(self.parameters)
        elif self.type in {"requires", "requires_any"}:
            data["when"] = self.when
            data["require"] = list(self.require)
        elif self.type == "forbids":
            data["when"] = self.when
            data["forbid"] = list(self.forbid)
        if self.message:
            data["message"] = self.message
        return data

    def summary(self) -> str:
        if self.type == "exactly_one":
            return f"Exactly one: {', '.join(self.parameters)}"
        if self.type == "at_most_one":
            return f"At most one: {', '.join(self.parameters)}"
        if self.type == "at_least_one":
            return f"At least one: {', '.join(self.parameters)}"
        if self.type == "all_or_none":
            return f"All or none: {', '.join(self.parameters)}"
        if self.type == "requires":
            return f"If {self.when} -> {', '.join(self.require)}"
        if self.type == "requires_any":
            return f"If {self.when} -> any of {', '.join(self.require)}"
        if self.type == "forbids":
            return f"If {self.when} -> not {', '.join(self.forbid)}"
        return self.type


@dataclass(frozen=True)
class ConstraintViolation:
    constraint_id: str
    message: str
    strict: bool = False

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.constraint_id,
            "message": self.message,
            "strict": self.strict,
        }


def _names(value: Any) -> tuple[str, ...]:
    if not isinstance(value, list):
        return ()
    result: list[str] = []
    seen: set[str] = set()
    for item in value:
        name = str(item).strip()
        if not name or name.casefold() in seen:
            continue
        seen.add(name.casefold())
        result.append(name)
    return tuple(result)


def is_parameter_active(values: Mapping[str, str | bool], name: str) -> bool:
    if name not in values:
        return False
    value = values[name]
    if isinstance(value, bool):
        return value
    text = str(value).strip()
    return bool(text) and text.upper() not in _FALSE_VALUES


def evaluate_constraints(
    values: Mapping[str, str | bool],
    constraints: tuple[ParameterConstraint, ...],
) -> list[ConstraintViolation]:
    violations: list[ConstraintViolation] = []
    for constraint in constraints:
        if constraint.type == "exactly_one":
            active = [
                name
                for name in constraint.parameters
                if is_parameter_active(values, name)
            ]
            if len(active) != 1:
                message = constraint.message or (
                    "Exactly one of these parameters must be active: "
                    + ", ".join(constraint.parameters)
                    + "."
                )
                violations.append(
                    ConstraintViolation(constraint.id, message, constraint.strict)
                )
        elif constraint.type == "at_most_one":
            active = [
                name
                for name in constraint.parameters
                if is_parameter_active(values, name)
            ]
            if len(active) > 1:
                message = constraint.message or (
                    "At most one of these parameters can be active: "
                    + ", ".join(constraint.parameters)
                    + "."
                )
                violations.append(
                    ConstraintViolation(constraint.id, message, constraint.strict)
                )
        elif constraint.type == "at_least_one":
            active = [
                name
                for name in constraint.parameters
                if is_parameter_active(values, name)
            ]
            if not active:
                message = constraint.message or (
                    "At least one of these parameters must be active: "
                    + ", ".join(constraint.parameters)
                    + "."
                )
                violations.append(
                    ConstraintViolation(constraint.id, message, constraint.strict)
                )
        elif constraint.type == "all_or_none":
            active = [
                name
                for name in constraint.parameters
                if is_parameter_active(values, name)
            ]
            if 0 < len(active) < len(constraint.parameters):
                message = constraint.message or (
                    "Either all or none of these parameters must be active: "
                    + ", ".join(constraint.parameters)
                    + "."
                )
                violations.append(
                    ConstraintViolation(constraint.id, message, constraint.strict)
                )
        elif constraint.type in {"requires", "requires_any"} and constraint.when:
            if not is_parameter_active(values, constraint.when):
                continue
            active = [
                name
                for name in constraint.require
                if is_parameter_active(values, name)
            ]
            if constraint.type == "requires":
                missing = [
                    name for name in constraint.require if name not in active
                ]
                if missing:
                    message = constraint.message or (
                        f"If {constraint.when} is active, these parameters must "
                        "also be active: "
                        + ", ".join(missing)
                        + "."
                    )
                    violations.append(
                        ConstraintViolation(
                            constraint.id, message, constraint.strict
                        )
                    )
            elif not active:
                message = constraint.message or (
                    f"If {constraint.when} is active, at least one of these "
                    "parameters must also be active: "
                    + ", ".join(constraint.require)
                    + "."
                )
                violations.append(
                    ConstraintViolation(constraint.id, message, constraint.strict)
                )
        elif constraint.type == "forbids" and constraint.when:
            if not is_parameter_active(values, constraint.when):
                continue
            forbidden = [
                name
                for name in constraint.forbid
                if is_parameter_active(values, name)
            ]
            if forbidden:
                message = constraint.message or (
                    f"If {constraint.when} is active, these parameters cannot "
                    "be active: "
                    + ", ".join(forbidden)
                    + "."
                )
                violations.append(
                    ConstraintViolation(constraint.id, message, constraint.strict)
                )
    return violations
