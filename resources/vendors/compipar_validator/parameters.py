from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


class ParametersFileError(ValueError):
    pass


@dataclass(frozen=True)
class ParameterEntry:
    key: str
    value: str
    is_flag: bool
    section: str
    line_index: int


def parse_parameter_entries(path: Path) -> tuple[ParameterEntry, ...]:
    path = Path(path)
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ParametersFileError(f"Could not read parameters file: {exc}") from exc
    result: list[ParameterEntry] = []
    section = "general"
    for index, line in enumerate(text.splitlines()):
        stripped = line.strip()
        if stripped.startswith("#"):
            section = _section_for(stripped, section)
            continue
        if not stripped:
            continue
        if "=" in stripped:
            key, value = stripped.split("=", 1)
            result.append(
                ParameterEntry(
                    key=key.strip(),
                    value=value.strip(),
                    is_flag=False,
                    section=section,
                    line_index=index,
                )
            )
        else:
            result.append(
                ParameterEntry(
                    key=stripped,
                    value="",
                    is_flag=True,
                    section=section,
                    line_index=index,
                )
            )
    return tuple(result)


def parse_parameters(path: Path) -> dict[str, str | bool]:
    values: dict[str, str | bool] = {}
    for entry in parse_parameter_entries(path):
        values[entry.key] = True if entry.is_flag else entry.value
    return values


def _section_for(line: str, current: str) -> str:
    upper = line.upper()
    if "REQUIRED" in upper or "REQUERID" in upper:
        return "required"
    if "OPTIONAL" in upper or "OPCIONAL" in upper:
        return "optional"
    if "FLAG" in upper:
        return "flags"
    return current
