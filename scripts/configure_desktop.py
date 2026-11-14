#!/usr/bin/env python3
"""Install the managed appearance without discarding other Noctalia state."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import tempfile
import tomllib


def section_path(header):
    data = tomllib.loads(header + "\n__dotfiles_section__ = true\n")
    path = []
    while "__dotfiles_section__" not in data:
        key, data = next(iter(data.items()))
        path.append(key)
    return tuple(path)


def appearance_state(text, config, wallpaper):
    """Remove saved values owned by the preset and select its wallpaper."""
    tomllib.loads(text)
    output, section, selected = [], (), set()
    lines = iter(text.splitlines(keepends=True))
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("[["):
            section = ()
        elif stripped.startswith("["):
            section = section_path(stripped)
            if section in (("wallpaper", "default"), ("wallpaper", "last")):
                output.extend((line, "    path = " + json.dumps(str(wallpaper)) + "\n"))
                selected.add(section)
                continue
        match = re.match(r'''\s*((?:"(?:[^"\\]|\\.)*"|'[^']*'|[A-Za-z0-9_-]+))\s*=''', line)
        if match:
            key = next(iter(tomllib.loads(match[1] + " = 0")))
            wallpaper_section = section in (("wallpaper", "default"), ("wallpaper", "last")) or section[:2] == ("wallpaper", "monitors")
            if wallpaper_section and key == "path":
                if section not in selected:
                    output.append("    path = " + json.dumps(str(wallpaper)) + "\n")
                selected.add(section)
                continue
            managed = config
            for part in section:
                managed = managed.get(part, {}) if isinstance(managed, dict) else {}
            owns_section = section[:1] in (("theme",), ("bar",), ("widget",), ("accessibility",)) or section == ("shell",) and key == "font_family" or section == ("wallpaper", "automation")
            if section == ("theme",) and key == "mode":
                # dotfiles-theme owns mode, including its saved light setting.
                owns_section = False
            if owns_section and isinstance(managed, dict) and key in managed:
                # Noctalia emits inline values; accept multiline arrays too.
                value = line
                while True:
                    try:
                        tomllib.loads(value)
                        break
                    except tomllib.TOMLDecodeError:
                        value += next(lines)
                continue
        output.append(line)
    result = "".join(output).rstrip() + "\n"
    for section in (("wallpaper", "default"), ("wallpaper", "last")):
        if section not in selected:
            result += "\n[" + ".".join(section) + "]\n    path = " + json.dumps(str(wallpaper)) + "\n"
    tomllib.loads(result)
    return result


def configure(config_path, state_path, wallpaper, dry_run=False):
    config = tomllib.loads(config_path.read_text())
    state_path = state_path.resolve()
    before = state_path.read_text() if state_path.exists() else ""
    after = appearance_state(before, config, wallpaper)
    if tomllib.loads(before) == tomllib.loads(after):
        return
    if dry_run:
        print(f"Would update managed Noctalia appearance and wallpaper: {state_path}")
        return
    state_path.parent.mkdir(parents=True, exist_ok=True)
    if state_path.exists():
        backup = Path(tempfile.mkdtemp(prefix=state_path.name + ".bak.", dir=state_path.parent)) / "original"
        shutil.copy2(state_path, backup)
        print(f"Backed up: {state_path} -> {backup}")
    fd, temporary = tempfile.mkstemp(prefix=".dotfiles-", dir=state_path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(after)
        if state_path.exists():
            shutil.copymode(state_path, temporary)
        os.replace(temporary, state_path)
    finally:
        Path(temporary).unlink(missing_ok=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("config", type=Path)
    parser.add_argument("state", type=Path)
    parser.add_argument("wallpaper", type=Path)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    configure(args.config, args.state, args.wallpaper, args.dry_run)
