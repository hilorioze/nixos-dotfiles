import os
import re
import time
from typing import Any


def is_reset(snapshot: dict[str, Any], now: float) -> bool:
    resets: list[float | None] = [window["resets_at"] for pool in snapshot["pools"] for window in pool["windows"]]

    return any(reset_at is not None and reset_at < now for reset_at in resets)


def match_pools(model: str, pools: list[dict[str, Any]]) -> list[dict[str, Any]]:
    matching: list[dict[str, Any]] = [
        pool for pool in pools
        if pool["name"] and any(word in model for word in re.findall(r"[a-z]{3,}", pool["name"].lower()))
    ]

    return matching or pools


def measure_part(part: str, parts: set[str]) -> int:
    shared: int = max((len(os.path.commonprefix([part, other])) for other in parts - {part}), default=0)

    length: int = max(shared + 1, 3)  # the shortest prefix no other part starts with, still readable

    return length if len(part) - length > 2 else len(part)  # the ellipsis takes a character itself


def shorten(part: str, length: int) -> str:
    return part if length >= len(part) else f"{part[:length]}…"


def abbreviate_label(label: str, labels: set[str], width: int) -> str:
    # an email shrinks by its name and host, the zone stays; any other label shrinks as a whole
    user, at, domain = label.partition("@")
    host, dot, zone = domain.rpartition(".")

    users: set[str] = {other.partition("@")[0] for other in labels}
    hosts: set[str] = {other.partition("@")[2].rpartition(".")[0] for other in labels}

    minimums: list[int] = [measure_part(user, users), measure_part(host, hosts)]
    lengths: list[int] = [len(user), len(host)]

    name: str = label

    # the part with more to spare shrinks first, never below what tells the accounts apart
    while len(name) > width and lengths != minimums:
        index: int = 0 if lengths[0] - minimums[0] >= lengths[1] - minimums[1] else 1
        lengths[index] -= 1

        name = f"{shorten(user, lengths[0])}{at}{shorten(host, lengths[1])}{dot}{zone}"

    return name


def format_reset(resets_at: float | None, now: float) -> str | None:
    if resets_at is None or resets_at <= now:
        return None

    minutes: int = int(resets_at - now) // 60
    days, hours = divmod(minutes // 60, 24)

    if days:
        return f"↻{days}d{hours}h"

    if hours:
        return f"↻{hours}h{minutes % 60}m"

    return f"↻{minutes}m"


def describe_window(window: dict[str, Any], now: float) -> str:
    return f"{window['label']} {round(window['remaining'])}%{format_reset(window['resets_at'], now) or ''}"


def format_account(account: dict[str, Any], pool: dict[str, Any], labels: set[str], width: int) -> str:
    now: float = time.time()

    windows: list[str] = [describe_window(window, now) for window in pool["windows"]]

    quota: str = " ".join(filter(None, [*windows, "(stale)" if account["stale"] else None]))

    return " ".join(filter(None, [abbreviate_label(account["label"], labels, width - len(quota) - 1), quota]))


def describe_quota(model: str, accounts: list[dict[str, Any]], labels: set[str], width: int) -> str:
    quotas: list[str] = [format_account(account, pool, labels, width) for account in accounts for pool in match_pools(model, account["pools"])]

    return "\n".join(quotas)
