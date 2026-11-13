from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Any

from .result import MetadataIssue
from .validation import ParameterConstraint

WIDGETS = (
    "text",
    "file",
    "directory",
    "path",
    "integer",
    "decimal",
    "slider",
    "select",
    "multiselect",
    "file_list",
    "path_list",
    "boolean",
    "flag",
)

_KNOWN_METADATA = {
    "widget",
    "label",
    "group",
    "order",
    "help",
    "placeholder",
    "options",
    "separator",
    "mode",
    "filters",
    "min",
    "max",
    "step",
    "decimals",
    "unit",
    "readonly",
    "hidden",
    "advanced",
    "strict",
    "required_value",
    "allow_tokens",
}
_KNOWN_DOCUMENT = {"schema_version", "parameters", "validations"}


@dataclass(frozen=True)
class ParameterMetadata:
    widget: str = "text"
    label: str | None = None
    group: str | None = None
    order: int | None = None
    help: str | None = None
    placeholder: str | None = None
    options: tuple[tuple[str, str], ...] = ()
    separator: str = ","
    mode: str = "open"
    filters: tuple[str, ...] = ()
    min_value: float | None = None
    max_value: float | None = None
    step: float | None = None
    decimals: int = 0
    unit: str | None = None
    readonly: bool = False
    hidden: bool = False
    advanced: bool = False
    strict: bool = False
    required_value: bool = False
    allow_tokens: bool = True
    extra: Mapping[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: Mapping[str, Any]) -> ParameterMetadata:
        options: list[tuple[str, str]] = []
        raw_options = data.get("options") or []
        if isinstance(raw_options, list):
            for option in raw_options:
                if isinstance(option, Mapping):
                    value = str(option.get("value", ""))
                    options.append((value, str(option.get("label") or value)))
                else:
                    options.append((str(option), str(option)))
        filters = data.get("filters") or []
        return cls(
            widget=str(data.get("widget") or "text"),
            label=str(data["label"]) if data.get("label") else None,
            group=str(data["group"]) if data.get("group") else None,
            order=_int_or_none(data.get("order")),
            help=str(data["help"]) if data.get("help") else None,
            placeholder=(
                str(data["placeholder"]) if data.get("placeholder") else None
            ),
            options=tuple(options),
            separator=str(data.get("separator") or ","),
            mode=str(data.get("mode") or "open"),
            filters=(
                tuple(str(item) for item in filters)
                if isinstance(filters, list)
                else ()
            ),
            min_value=_number(data.get("min")),
            max_value=_number(data.get("max")),
            step=_number(data.get("step")),
            decimals=_int_or_none(data.get("decimals")) or 0,
            unit=str(data["unit"]) if data.get("unit") else None,
            readonly=bool(data.get("readonly")),
            hidden=bool(data.get("hidden")),
            advanced=bool(data.get("advanced")),
            strict=bool(data.get("strict")),
            required_value=bool(data.get("required_value")),
            allow_tokens=bool(data.get("allow_tokens", True)),
            extra={
                key: value
                for key, value in data.items()
                if key not in _KNOWN_METADATA
            },
        )

    def to_dict(self) -> dict[str, Any]:
        data = dict(self.extra)
        data.update(
            {
                "widget": self.widget,
                "separator": self.separator,
                "mode": self.mode,
                "filters": list(self.filters),
                "decimals": self.decimals,
                "readonly": self.readonly,
                "hidden": self.hidden,
                "advanced": self.advanced,
                "strict": self.strict,
                "required_value": self.required_value,
                "allow_tokens": self.allow_tokens,
            }
        )
        for key, value in (
            ("label", self.label),
            ("group", self.group),
            ("order", self.order),
            ("help", self.help),
            ("placeholder", self.placeholder),
            ("min", self.min_value),
            ("max", self.max_value),
            ("step", self.step),
            ("unit", self.unit),
        ):
            if value is not None:
                data[key] = value
        if self.options:
            data["options"] = [
                {"value": value, "label": label}
                for value, label in self.options
            ]
        return data


@dataclass(frozen=True)
class ParameterMetadataDocument:
    parameters: dict[str, ParameterMetadata] = field(default_factory=dict)
    validations: tuple[ParameterConstraint, ...] = ()
    metadata_issues: tuple[MetadataIssue, ...] = ()
    schema_version: int = 1
    extra: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, data: Any) -> ParameterMetadataDocument:
        if not isinstance(data, Mapping):
            return cls(
                metadata_issues=(
                    MetadataIssue("parameters.metadata.json must be an object"),
                )
            )
        raw_parameters = data.get("parameters") or {}
        parameters: dict[str, ParameterMetadata] = {}
        issues: list[MetadataIssue] = []
        if isinstance(raw_parameters, Mapping):
            for name, value in raw_parameters.items():
                if isinstance(value, Mapping):
                    parameters[str(name)] = ParameterMetadata.from_dict(value)
                else:
                    issues.append(
                        MetadataIssue(
                            "Invalid parameter metadata; expected an object",
                            context=str(name),
                        )
                    )
        else:
            issues.append(
                MetadataIssue("'parameters' must be an object", context="parameters")
            )
        raw_validations = data.get("validations") or []
        validations: list[ParameterConstraint] = []
        if isinstance(raw_validations, list):
            for index, raw in enumerate(raw_validations):
                constraint = ParameterConstraint.from_dict(raw)
                if constraint is None:
                    issues.append(
                        MetadataIssue(
                            "Invalid validation rule; the rule was ignored",
                            context=f"validations[{index}]",
                        )
                    )
                else:
                    validations.append(constraint)
        else:
            issues.append(
                MetadataIssue(
                    "'validations' must be an array",
                    context="validations",
                )
            )
        return cls(
            parameters=parameters,
            validations=tuple(validations),
            metadata_issues=tuple(issues),
            schema_version=_int_or_none(data.get("schema_version")) or 1,
            extra={
                key: value
                for key, value in data.items()
                if key not in _KNOWN_DOCUMENT
            },
        )

    def to_dict(self) -> dict[str, Any]:
        data = dict(self.extra)
        data.update(
            {
                "schema_version": self.schema_version,
                "parameters": {
                    name: metadata.to_dict()
                    for name, metadata in sorted(self.parameters.items())
                },
            }
        )
        if self.validations:
            data["validations"] = [
                constraint.to_dict() for constraint in self.validations
            ]
        return data


def _int_or_none(value: Any) -> int | None:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _number(value: Any) -> float | None:
    if value is None or value == "":
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None
