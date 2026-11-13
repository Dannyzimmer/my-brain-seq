from __future__ import annotations

import json
import os
import shutil
import tempfile
from pathlib import Path

from .metadata import ParameterMetadataDocument


class MetadataFileError(ValueError):
    pass


def load_metadata(
    path: Path,
    *,
    missing_ok: bool = True,
) -> ParameterMetadataDocument:
    path = Path(path)
    if not path.is_file():
        if missing_ok:
            return ParameterMetadataDocument()
        raise MetadataFileError(f"Metadata file does not exist: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise MetadataFileError(f"Could not read metadata file: {exc}") from exc
    return ParameterMetadataDocument.from_dict(data)


def save_metadata(path: Path, document: ParameterMetadataDocument) -> None:
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(
        dir=str(path.parent),
        prefix=f".{path.name}.",
        suffix=".tmp",
    )
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            json.dump(
                document.to_dict(),
                handle,
                indent=2,
                ensure_ascii=False,
            )
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        if path.is_file():
            shutil.copy2(path, path.with_name(path.name + ".bak"))
        os.replace(tmp_path, path)
    finally:
        tmp_path.unlink(missing_ok=True)
