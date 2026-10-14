import asyncio
import json
import math
import os
import sys
import time
from collections import defaultdict
from collections.abc import Callable, Coroutine
from pathlib import Path
from typing import Any

from cliproxyapi_accounts import (
    ACCOUNT_ERRORS,
    FETCHERS,
    WINDOW_LENGTHS,
    call_management,
    print_account_error,
    send_provider_request,
)

POLL_INTERVAL: float = 300  # banked and early resets come unannounced

RESET_TOLERANCE: float = 60  # antigravity replicas disagree slightly on a window's reset
RESET_DELAY: float = 5  # a window read right at its reset may still show the old one

SLOT_LENGTH: int = 900
WEEK_SLOTS: int = 7 * 86400 // SLOT_LENGTH
DEMAND_HALF_LIFE: float = 14 * 86400  # habits drift; two-week-old demand counts half
SAME_WEEKDAY_WEIGHT: float = 6  # a weekday's own history weighs as much as the other six days together
PLAN_HORIZON: int = 86400  # a start moves every reset after it up to the next quiet hours

DEMAND_PATH: Path = Path(os.environ["STATE_DIRECTORY"]) / "demand.json"

ANTIGRAVITY_WARMUP_MODELS: dict[str | None, str] = {
    "Gemini Models": "gemini-3.8-flash-tiered",  # older gemini models are not metered and never start the window
    "Claude and GPT models": "gpt-oss-120b-medium",
}


async def warm_claude(account: dict[str, Any], pool: str | None) -> None:
    await send_provider_request(
        account,
        "POST",
        "https://api.anthropic.com/v1/messages",
        {"Content-Type": "application/json", "anthropic-version": "2023-06-01", "anthropic-beta": "oauth-2025-04-20"},
        json.dumps({"model": "claude-haiku-4-5", "max_tokens": 1, "messages": [{"role": "user", "content": "hi"}]}),
    )


async def warm_codex(account: dict[str, Any], pool: str | None) -> None:
    await send_provider_request(
        account,
        "POST",
        "https://chatgpt.com/backend-api/codex/responses",
        {"Content-Type": "application/json"},
        json.dumps({"model": "gpt-6-luna", "input": [{"role": "user", "content": "hi"}], "store": False, "stream": True}),  # refused unless streamed and unstored
    )


async def warm_antigravity(account: dict[str, Any], pool: str | None) -> None:
    await send_provider_request(
        account,
        "POST",
        "https://daily-cloudcode-pa.googleapis.com/v1internal:generateContent",
        {"Content-Type": "application/json", "User-Agent": "antigravity"},
        json.dumps({
            "project": account["project_id"],
            "model": ANTIGRAVITY_WARMUP_MODELS[pool],
            "request": {"contents": [{"role": "user", "parts": [{"text": "hi"}]}], "generationConfig": {"maxOutputTokens": 1}},
        }),
    )


# one minimal request starts every window of the pool it is spent from
WARMERS: dict[str, Callable[[dict[str, Any], str | None], Coroutine[Any, Any, None]]] = {
    "claude": warm_claude,
    "codex": warm_codex,
    "antigravity": warm_antigravity,
}


def join_names(*names: str | None) -> str:
    return " ".join(name for name in names if name)


def is_idle(window: dict[str, Any], fetched_at: float) -> bool:
    return window["resets_at"] is None or window["resets_at"] <= fetched_at


def is_warmable(entry: dict[str, Any]) -> bool:
    # a request is refused while some window of the pool is spent
    return all(window["remaining"] > 0 for window in entry["pool"]["windows"])


def has_idle_longer_window(entry: dict[str, Any]) -> bool:
    # an idle 5h window waits for its group's plan
    if entry["window"] is not None and is_idle(entry["window"], entry["fetched_at"]):
        return False

    return any(is_idle(window, entry["fetched_at"]) for window in entry["pool"]["windows"])


def find_entry_id(entry: dict[str, Any]) -> tuple[str, str | None]:
    return entry["account"]["auth_index"], entry["pool"]["name"]


def find_slot(at: float) -> int:
    moment: time.struct_time = time.gmtime(at)  # a DST switch shifts the learned demand by an hour until it is relearned

    return (moment.tm_wday * 86400 + moment.tm_hour * 3600 + moment.tm_min * 60) // SLOT_LENGTH


def decay(weight: float, since: float, now: float) -> float:
    return weight * 0.5 ** ((now - since) / DEMAND_HALF_LIFE)


def record_demand(profile: list[list[float]], at: float, spent: float, duration: float) -> None:
    slot: int = find_slot(at)
    slot_spent, slot_duration, updated_at = profile[slot]

    profile[slot] = [decay(slot_spent, updated_at, at) + spent, decay(slot_duration, updated_at, at) + duration, at]


def forecast_demand(profile: list[list[float]], at: float, now: float) -> float:
    slot: int = find_slot(at)
    spent: float = 0
    duration: float = 0

    for day in range(7):
        day_spent, day_duration, updated_at = profile[(slot + day * WEEK_SLOTS // 7) % WEEK_SLOTS]
        weight: float = decay(SAME_WEEKDAY_WEIGHT if day == 0 else 1, updated_at, now)

        spent += weight * day_spent
        duration += weight * day_duration

    return spent / duration * SLOT_LENGTH if duration else 0  # nothing learned yet plans plain chaining


def measure_spending(before: dict[str, Any], window: dict[str, Any]) -> float:
    # a window keeps its reset time; everything spent from a new one is new
    if before["resets_at"] is not None and window["resets_at"] is not None and abs(window["resets_at"] - before["resets_at"]) < RESET_TOLERANCE:
        return max(before["remaining"] - window["remaining"], 0)

    return 100 - window["remaining"]


def learn_demand(profile: list[list[float]], members: list[dict[str, Any]], previous: dict[tuple[str, str | None], dict[str, Any]]) -> None:
    compared: list[dict[str, Any]] = [member for member in members if find_entry_id(member) in previous]

    if not compared:
        return

    duration: float = sum(member["fetched_at"] - previous[find_entry_id(member)]["fetched_at"] for member in compared) / len(compared)
    spent: float = sum(measure_spending(previous[find_entry_id(member)]["window"], member["window"]) for member in compared)

    # the demand of a spent group goes unseen; it was at least a window per window length
    if all(member["window"]["remaining"] <= 0 for member in members):
        spent += len(members) * 100 * duration / WINDOW_LENGTHS["5h"]

    record_demand(profile, compared[0]["fetched_at"] - duration / 2, spent, duration)


def simulate_serving(windows: list[dict[str, Any]], starts: list[float | None], demands: list[float], now: float) -> float:
    resets: list[float | None] = [window["resets_at"] for window in windows]
    remaining: list[float] = [window["remaining"] for window in windows]
    pending: list[float | None] = list(starts)
    served: float = 0

    for step, demand in enumerate(demands):
        at: float = now + step * SLOT_LENGTH

        for index, (reset, start) in enumerate(zip(resets, pending)):
            if reset is not None and reset <= at:
                reset = None
                remaining[index] = 100

            if reset is None and start is not None and start <= at:
                reset = at + WINDOW_LENGTHS["5h"]
                pending[index] = None

            resets[index] = reset

        # as the priorities route: the window that resets first is spent first, an idle one only when the rest are spent
        for index in sorted(range(len(windows)), key=lambda position: resets[position] or math.inf):
            spent: float = min(demand, remaining[index])

            if spent > 0 and resets[index] is None:
                resets[index] = at + WINDOW_LENGTHS["5h"]

            remaining[index] -= spent
            demand -= spent
            served += spent

    return served


def plan_warmups(members: list[dict[str, Any]], demands: list[float], now: float) -> list[dict[str, Any]]:
    # a pool with a longer window spent serves nothing
    usable: list[dict[str, Any]] = [
        member for member in members if all(window["remaining"] > 0 for window in member["pool"]["windows"] if window["length"] != WINDOW_LENGTHS["5h"])
    ]

    windows: list[dict[str, Any]] = []

    for member in usable:
        idle: bool = is_idle(member["window"], member["fetched_at"])

        windows.append({"resets_at": None if idle else member["window"]["resets_at"], "remaining": 100 if idle else member["window"]["remaining"]})

    idle_indexes: list[int] = [index for index, window in enumerate(windows) if window["resets_at"] is None]
    options: list[float | None] = [now + step * SLOT_LENGTH for step in range(WINDOW_LENGTHS["5h"] // SLOT_LENGTH + 1)] + [None]  # None waits for the first request
    starts: list[float | None] = [None] * len(windows)

    # every idle window takes its best start given the others'; the second round lets them settle together
    for index in idle_indexes * 2:
        served: list[float] = [round(simulate_serving(windows, starts[:index] + [start] + starts[index + 1:], demands, now), 6) for start in options]  # float noise must not beat an earlier start

        starts[index] = options[served.index(max(served))]  # of equal plans the earliest, it starts the longer windows sooner

    return [usable[index] for index in idle_indexes if starts[index] == now]


def rank_spending(entries: list[dict[str, Any]]) -> tuple[int, float]:
    resets: list[float] = [entry["window"]["resets_at"] for entry in entries if entry["window"] is not None and not is_idle(entry["window"], entry["fetched_at"])]

    if resets:
        return 0, min(resets)

    # an idle 5h window waits for its planned start behind accounts that have none
    if all(entry["window"] is None for entry in entries):
        return 1, 0

    return 2, 0


async def route_spending(entries: list[dict[str, Any]], priorities: dict[str, int]) -> None:
    accounts: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)

    for entry in entries:
        accounts[entry["account"]["name"]].append(entry)

    providers: defaultdict[str, list[str]] = defaultdict(list)

    for name, account_entries in accounts.items():
        providers[account_entries[0]["account"]["provider"]].append(name)

    for names in providers.values():
        names.sort(key=lambda name: rank_spending(accounts[name]))

        # cliproxyapi spends the highest priority first; a session stays on its account until it is spent
        for position, name in enumerate(names):
            priority: int = len(names) - position

            if priorities.get(name) != priority:
                await call_management("PATCH", "/auth-files/fields", {"name": name, "priority": priority})
                priorities[name] = priority


async def fetch_entries(accounts: list[dict[str, Any]]) -> list[dict[str, Any]]:
    entries: list[dict[str, Any]] = []

    for account in accounts:
        if account["disabled"]:
            continue

        try:
            pools: list[dict[str, Any]] = await FETCHERS[account["provider"]](account)
        except ACCOUNT_ERRORS as error:
            print_account_error(account, error)

            continue

        fetched_at: float = time.time()

        for pool in pools:
            window: dict[str, Any] | None = next((window for window in pool["windows"] if window["length"] == WINDOW_LENGTHS["5h"]), None)

            entries.append({"account": account, "pool": pool, "window": window, "fetched_at": fetched_at})

    return entries


async def warm_pool(entry: dict[str, Any]) -> None:
    idle: list[dict[str, Any]] = [window for window in entry["pool"]["windows"] if is_idle(window, entry["fetched_at"])]
    labels: str = ", ".join(window["label"] for window in idle)

    try:
        await WARMERS[entry["account"]["provider"]](entry["account"], entry["pool"]["name"])
    except ACCOUNT_ERRORS as error:
        print_account_error(entry["account"], error)

        return

    # routing this round must already see the windows running
    for window in idle:
        window["resets_at"] = time.time() + window["length"]

    print(f"{join_names(entry['account']['provider'], entry['account']['label'], entry['pool']['name'])}: warmed {labels}", file=sys.stderr)


async def warm_quotas() -> None:
    profiles: defaultdict[str, list[list[float]]] = defaultdict(lambda: [[0, 0, 0] for _ in range(WEEK_SLOTS)])

    if DEMAND_PATH.exists():
        profiles.update(json.loads(DEMAND_PATH.read_text()))

    previous: dict[tuple[str, str | None], dict[str, Any]] = {}
    priorities: dict[str, int] = {}

    while True:
        entries: list[dict[str, Any]] = await fetch_entries((await call_management("GET", "/auth-files"))["files"])
        now: float = time.time()

        # accounts of a provider share the demand for a pool through failover
        groups: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)

        for entry in entries:
            if entry["window"] is not None:
                groups[join_names(entry["account"]["provider"], entry["pool"]["name"])].append(entry)

        for key, members in groups.items():
            learn_demand(profiles[key], members, previous)

            demands: list[float] = [forecast_demand(profiles[key], now + step * SLOT_LENGTH, now) for step in range(PLAN_HORIZON // SLOT_LENGTH)]

            for member in plan_warmups(members, demands, now):
                await warm_pool(member)

        # a write cut short would leave a file no later start can parse
        staged: Path = DEMAND_PATH.with_suffix(".tmp")
        staged.write_text(json.dumps(profiles))
        staged.replace(DEMAND_PATH)

        # the windows longer than 5h start as soon as they can: an hour of them idle is an hour lost
        for entry in entries:
            if has_idle_longer_window(entry) and is_warmable(entry):
                await warm_pool(entry)

        await route_spending(entries, priorities)

        previous = {find_entry_id(entry): entry for entry in entries}

        resets: list[float] = [window["resets_at"] for entry in entries for window in entry["pool"]["windows"] if window["resets_at"] is not None]
        next_reset: float = min((reset for reset in resets if reset > now), default=now + POLL_INTERVAL)

        await asyncio.sleep(min(next_reset - now + RESET_DELAY, POLL_INTERVAL))


def main() -> None:
    asyncio.run(warm_quotas())


if __name__ == "__main__":
    main()
