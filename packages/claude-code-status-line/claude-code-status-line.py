import json
import os
import sys
from typing import Any


def get(session: dict[str, Any], *keys: str) -> Any:
    value: Any = session

    for key in keys:
        if not isinstance(value, dict):
            return None

        value = value.get(key)

    return value


def colorize(code: int, text: str) -> str:
    return f"\033[{code}m{text}\033[0m"


def format_directory(directory: str) -> str:
    home: str = os.path.expanduser("~")

    if directory == home or directory.startswith(home + os.sep):
        return "~" + directory[len(home):]

    return directory


def format_limit(label: str, used_percentage: float) -> str:
    left: int = round(min(max(100 - used_percentage, 0), 100))

    return f"{label} {left}% left"


def main() -> None:
    session: dict[str, Any] = json.load(sys.stdin)

    items: list[str] = []

    directory: str | None = get(session, "workspace", "current_dir") or get(session, "cwd")
    if directory:
        items.append(colorize(32, format_directory(directory)))

    model: list[str | None] = [get(session, "model", "display_name"), get(session, "effort", "level")]
    if any(model):
        items.append(colorize(36, " ".join(filter(None, model))))

    five_hour: float | None = get(session, "rate_limits", "five_hour", "used_percentage")
    if five_hour is not None:
        items.append(colorize(35, format_limit("5h", five_hour)))

    weekly: float | None = get(session, "rate_limits", "seven_day", "used_percentage")
    if weekly is not None:
        items.append(colorize(35, format_limit("weekly", weekly)))

    context: float | None = get(session, "context_window", "used_percentage")
    if context is not None:
        items.append(colorize(32, f"Context {round(context)}% used"))

    session_id: str | None = get(session, "session_id")
    if session_id:
        items.append(colorize(36, session_id))

    print(colorize(2, " · ").join(items))


if __name__ == "__main__":
    main()
