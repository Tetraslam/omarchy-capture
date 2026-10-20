#!/usr/bin/env python3
"""Put one captured line at the top of a markdown note, below its frontmatter.

    capture.py FILE FORMAT TEXT

FORMAT is "task" (a "- [ ] " checkbox) or "line" (the text as is). The write is
atomic and keeps the note's permissions; a missing note is created. Plain file
writes work offline, and Obsidian Sync picks them up like any other edit.
"""

import os
from pathlib import Path
import sys
import tempfile


def entry(text, fmt):
    text = " ".join(text.split())
    return f"- [ ] {text}" if fmt == "task" else text


def insert(content, line):
    """New line first, after any frontmatter block."""
    lines = content.splitlines(keepends=True)
    at = 0
    if lines and lines[0].strip() == "---":
        for index in range(1, len(lines)):
            if lines[index].strip() == "---":
                at = index + 1
                break
    if lines and at == len(lines) and not lines[-1].endswith("\n"):
        lines[-1] += "\n"
    lines.insert(at, line + "\n")
    return "".join(lines)


def capture(path, fmt, text):
    path = Path(path).expanduser()
    line = entry(text, fmt)
    if not line or line == "- [ ] ":
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    content = path.read_text(encoding="utf-8") if path.exists() else ""
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    fd, name = tempfile.mkstemp(dir=path.parent, prefix="." + path.name + ".", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(insert(content, line))
        os.chmod(name, mode)
        os.replace(name, path)
    except BaseException:
        Path(name).unlink(missing_ok=True)
        raise
    return True


if __name__ == "__main__":
    if len(sys.argv) != 4 or sys.argv[2] not in ("task", "line"):
        sys.exit("usage: capture.py FILE task|line TEXT")
    sys.exit(0 if capture(*sys.argv[1:]) else 1)
