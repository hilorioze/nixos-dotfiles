import json
import os
import re
import sys
import urllib.parse
import urllib.request
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


def read_terminal_width() -> int:
    pid: int = os.getppid()

    # claude runs the command without a terminal, its own is the nearest ancestor's
    while True:
        with open(f"/proc/{pid}/stat") as file:
            fields: list[str] = file.read().rsplit(")", 1)[1].split()

        if int(fields[4]):
            break

        pid = int(fields[1])

    with open(f"/proc/{pid}/fd/0") as terminal:
        return os.get_terminal_size(terminal.fileno()).columns


def measure(line: str) -> int:
    return len(re.sub(r"\033\[[0-9;]*m", "", line))


def wrap(items: list[str], separator: str, width: int) -> list[str]:
    lines: list[list[str]] = [[]]

    for item in items:
        if lines[-1] and measure(separator.join([*lines[-1], item])) > width:
            lines.append([])

        lines[-1].append(item)

    return [separator.join(line) for line in lines]


def read_quota(model: str, width: int, every: bool) -> str:
    gateway: str | None = os.environ.get("ANTHROPIC_BASE_URL")
    if not gateway:
        return ""

    query: dict[str, Any] = {"model": model, "width": width} | ({"all": ""} if every else {})

    request: urllib.request.Request = urllib.request.Request(
        f"{gateway}/quotas?{urllib.parse.urlencode(query)}",
        headers={"Authorization": f"Bearer {os.environ['ANTHROPIC_AUTH_TOKEN']}"},
    )

    try:
        with urllib.request.urlopen(request, timeout=2) as response:
            return json.load(response)
    except OSError:
        return ""  # the limits claude reports itself are still shown


def main() -> None:
    session: dict[str, Any] = json.load(sys.stdin)

    items: list[str] = []

    directory: str | None = get(session, "workspace", "current_dir") or get(session, "cwd")
    if directory:
        items.append(colorize(32, format_directory(directory)))

    model: list[str | None] = [get(session, "model", "display_name"), get(session, "effort", "level")]
    if any(model):
        items.append(colorize(36, " ".join(filter(None, model))))

    tail: list[str] = []

    context: float | None = get(session, "context_window", "used_percentage")
    if context is not None:
        tail.append(colorize(32, f"Context {round(context)}% used"))

    session_id: str | None = get(session, "session_id")
    if session_id:
        tail.append(colorize(36, session_id))

    separator: str = colorize(2, " · ")

    width: int = read_terminal_width() - 4  # the footer pads both sides by two columns

    # the quota takes what is left of the line, then of the line without the tail, then a line of its own
    budgets: list[int] = [
        width - measure(separator.join(items + tail)) - measure(separator),
        width - measure(separator.join(items)) - measure(separator),
        width,
    ]

    model_id: str | None = get(session, "model", "id")

    # before the first answer there is no context yet, nor an account of the session: every one gets a line
    quotas: list[str] = read_quota(model_id, width, True).splitlines() if context is None and model_id else []

    if quotas:
        print("\n".join(wrap(items + tail, separator, width) + [colorize(35, quota) for quota in quotas]))

        return

    quota: str = ""

    for budget in budgets:
        quota = read_quota(model_id, budget, False) if model_id else ""

        if measure(quota) <= budget:
            break

    if quota:
        items.append(colorize(35, quota))

    five_hour: float | None = get(session, "rate_limits", "five_hour", "used_percentage")
    if five_hour is not None and not quota:
        items.append(colorize(35, format_limit("5h", five_hour)))

    weekly: float | None = get(session, "rate_limits", "seven_day", "used_percentage")
    if weekly is not None and not quota:
        items.append(colorize(35, format_limit("7d", weekly)))

    print("\n".join(wrap(items + tail, separator, width)))


if __name__ == "__main__":
    main()
