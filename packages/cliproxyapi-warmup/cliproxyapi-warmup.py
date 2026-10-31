import asyncio
import itertools
import json
import math
import os
import sys
import time
from collections import defaultdict
from collections.abc import Callable, Coroutine, Iterable
from functools import cache
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
PLAN_HORIZON: int = 86400

DEMAND_PATH: Path = Path(os.environ["STATE_DIRECTORY"]) / "demand.json"
BUDGET_PATH: Path = DEMAND_PATH.with_name("budgets.json")

ANTIGRAVITY_WARMUP_MODELS: dict[str | None, str] = {
    "Gemini Models": "gemini-3.8-flash-tiered",  # older gemini models are not metered and never start the window
    "Claude and GPT models": "gpt-oss-120b-medium",
}


def write_state(path: Path, state: dict[str, Any]) -> None:
    # a partial json file cannot be loaded on restart; write a copy and replace the old file atomically
    staged: Path = path.with_suffix(".tmp")
    staged.write_text(json.dumps(state))
    staged.replace(path)


def report(event: dict[str, Any]) -> None:
    print(json.dumps(event), file=sys.stderr)


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
        json.dumps({"model": "gpt-6-luna", "input": [{"role": "user", "content": "hi"}], "store": False, "stream": True}),  # codex answers 400 unless streamed and unstored
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
    # a request gets 429 while some window of the pool is spent
    return all(window["remaining"] > 0 for window in entry["pool"]["windows"])


def has_idle_longer_window(entry: dict[str, Any]) -> bool:
    # an idle 5h window waits for its group's plan
    if entry["window"] is not None and is_idle(entry["window"], entry["fetched_at"]):
        return False

    return any(is_idle(window, entry["fetched_at"]) for window in entry["pool"]["windows"])


def find_entry_id(entry: dict[str, Any]) -> tuple[str, str | None]:
    return entry["account"]["auth_index"], entry["pool"]["name"]


def find_group(entry: dict[str, Any]) -> str:
    return join_names(entry["account"]["provider"], entry["pool"]["name"])


def find_slot(at: float) -> int:
    moment: time.struct_time = time.gmtime(at)  # the accounts are shared, no one's zone fits; a DST switch shifts the learned demand by an hour until it is relearned

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


def crossed_reset(before: dict[str, Any], entry: dict[str, Any]) -> bool:
    windows: dict[int, dict[str, Any]] = {window["length"]: window for window in entry["pool"]["windows"]}

    for old in before["pool"]["windows"]:
        if is_idle(old, before["fetched_at"]):
            continue

        reset: float | None = windows[old["length"]]["resets_at"]
        if old["resets_at"] <= entry["fetched_at"] or reset is None or abs(reset - old["resets_at"]) >= RESET_TOLERANCE:
            return True

    return False


def measure_spending(before: dict[str, Any], window: dict[str, Any]) -> float:
    return max(before["remaining"] - window["remaining"], 0)


def learn_budget(before: dict[str, Any], entry: dict[str, Any], budgets: dict[str, dict[str, list[float]]]) -> None:
    windows: dict[int, dict[str, Any]] = {window["length"]: window for window in before["pool"]["windows"]}
    short_spent: float = measure_spending(before["window"], entry["window"])
    at: float = entry["fetched_at"]

    for window in entry["pool"]["windows"]:
        if window["length"] == WINDOW_LENGTHS["5h"]:
            continue

        spent: float = measure_spending(windows[window["length"]], window)
        if not short_spent and not spent:
            continue

        profile: dict[str, list[float]] = budgets.setdefault(join_names(*find_entry_id(entry)), {})
        key: str = str(window["length"])
        short_total, total, updated_at = profile.get(key, [0, 0, at])

        # sum the measured changes before dividing; individual rounded deltas often have a zero denominator
        profile[key] = [decay(short_total, updated_at, at) + short_spent, decay(total, updated_at, at) + spent, at]


def learn_demand(profile: list[list[float]], members: list[dict[str, Any]], previous: list[dict[str, Any]], budgets: dict[str, dict[str, list[float]]]) -> dict[str, Any]:
    before: dict[tuple[str, str | None], dict[str, Any]] = {find_entry_id(entry): entry for entry in previous}
    if before.keys() != {find_entry_id(entry) for entry in members}:
        return {"observation": "baseline"}

    stable: list[dict[str, Any]] = [entry for entry in members if not crossed_reset(before[find_entry_id(entry)], entry)]

    for entry in stable:
        learn_budget(before[find_entry_id(entry)], entry, budgets)

    if len(stable) != len(members):
        return {"observation": "reset"}

    duration: float = sum(entry["fetched_at"] - before[find_entry_id(entry)]["fetched_at"] for entry in members) / len(members)
    spent: float = sum(measure_spending(before[find_entry_id(entry)]["window"], entry["window"]) for entry in members)

    # exhausted limits hide unmet demand; exclude intervals without an available account
    if not any(is_warmable(entry) for entry in previous) or not any(is_warmable(entry) for entry in members):
        return {"observation": "unavailable", "duration": duration, "spent": spent}

    record_demand(profile, members[0]["fetched_at"] - duration / 2, spent, duration)

    return {"observation": "measured", "duration": duration, "spent": spent}


def rank_resets(resets: Iterable[float | None]) -> float:
    return min((reset for reset in resets if reset is not None), default=math.inf)


def prepare_simulation(members: list[dict[str, Any]], budgets: dict[str, dict[str, list[float]]], now: float) -> dict[str, Any]:
    lengths: list[list[int]] = []
    remaining: list[list[float]] = []
    resets: list[list[float | None]] = []
    costs: list[list[float | None]] = []
    accounts: defaultdict[str, list[int]] = defaultdict(list)
    groups: defaultdict[str, list[int]] = defaultdict(list)

    for index, member in enumerate(members):
        windows: list[dict[str, Any]] = [member["window"], *(window for window in member["pool"]["windows"] if window["length"] != WINDOW_LENGTHS["5h"])]
        profile: dict[str, list[float]] = budgets.get(join_names(*find_entry_id(member)), {})
        pool_costs: list[float | None] = [1]

        for window in windows[1:]:
            short_total, total, _ = profile.get(str(window["length"]), [0, 0, 0])
            pool_costs.append(total / short_total if short_total > 0 and total > 0 else None)

        lengths.append([window["length"] for window in windows])
        remaining.append([100 if is_idle(window, now) else window["remaining"] for window in windows])
        resets.append([None if is_idle(window, now) else window["resets_at"] for window in windows])
        costs.append(pool_costs)
        accounts[member["account"]["auth_index"]].append(index)
        groups[find_group(member)].append(index)

    return {"lengths": lengths, "remaining": remaining, "resets": resets, "costs": costs, "accounts": list(accounts.values()), "groups": dict(groups)}


def advance_pool(lengths: list[int], remaining: list[float], resets: list[float | None], at: float, *, warm: bool = False) -> None:
    for position, reset in enumerate(resets):
        if reset is not None and reset <= at:
            resets[position] = None
            remaining[position] = 100

    if not all(value > 0 for value in remaining):
        return

    if resets[0] is None and warm:
        resets[0] = at + lengths[0]

    if resets[0] is not None:
        for position, reset in enumerate(resets):
            if reset is None:
                resets[position] = at + lengths[position]


def spend_pool(lengths: list[int], remaining: list[float], resets: list[float | None], costs: list[float | None], demand: float, at: float) -> float:
    if not all(value > 0 for value in remaining):
        return 0

    available: float = min(value / cost for value, cost in zip(remaining, costs) if cost is not None)
    spent: float = min(demand, available)
    if spent <= 0:
        return 0

    advance_pool(lengths, remaining, resets, at, warm=True)

    for position, cost in enumerate(costs):
        if cost is not None:
            remaining[position] = max(remaining[position] - spent * cost, 0)

    return spent


def plan_pool(simulation: dict[str, Any], index: int, demand: list[float], now: float) -> dict[float | None, tuple[float, ...]]:
    lengths: list[int] = simulation["lengths"][index]
    initial_remaining: list[float] = simulation["remaining"][index]
    initial_resets: list[float | None] = simulation["resets"][index]
    costs: list[float | None] = simulation["costs"][index]
    horizon: int = len(demand)
    window_steps: int = math.ceil(lengths[0] / SLOT_LENGTH)
    suffix: list[float] = [0] * (horizon + 1)

    for step in range(horizon - 1, -1, -1):
        suffix[step] = suffix[step + 1] + demand[step]

    def continue_plan(step: int, remaining: list[float], resets: list[float | None]) -> tuple[float, tuple[float, ...]]:
        capacity: float = min(suffix[step], 100 * (math.ceil((horizon - step) / window_steps) + 1))

        # merge nonbinding budgets to avoid searching equivalent window schedules
        for position, cost in enumerate(costs[1:], 1):
            if remaining[position] > 0 and (cost is None or remaining[position] / cost >= capacity):
                remaining[position] = 100
                resets[position] = now + PLAN_HORIZON + lengths[position]

        return solve(step, tuple(remaining), tuple(resets))

    def finish_window(step: int, end: int, remaining: list[float], resets: list[float | None]) -> tuple[float, tuple[float, ...]]:
        served: float = 0

        for tick in range(step, end):
            at: float = now + tick * SLOT_LENGTH
            advance_pool(lengths, remaining, resets, at)
            served += spend_pool(lengths, remaining, resets, costs, demand[tick], at)

        future: float
        plan: tuple[float, ...]
        future, plan = continue_plan(end, remaining, resets)

        return served + future, plan

    # choose later starts at each reset so the forecast includes shifts across quiet gaps
    @cache
    def solve(step: int, balances: tuple[float, ...], deadlines: tuple[float | None, ...]) -> tuple[float, tuple[float, ...]]:
        if step >= horizon:
            return 0, ()

        at: float = now + step * SLOT_LENGTH
        remaining: list[float] = list(balances)
        resets: list[float | None] = list(deadlines)
        advance_pool(lengths, remaining, resets, at)
        reset: float | None = resets[0]
        if reset is not None:
            return finish_window(step, min(math.ceil((reset - now) / SLOT_LENGTH), horizon), remaining, resets)

        if not all(value > 0 for value in remaining):
            return continue_plan(step + 1, remaining, resets)

        warmed_remaining: list[float] = list(remaining)
        warmed_resets: list[float | None] = list(resets)
        advance_pool(lengths, warmed_remaining, warmed_resets, at, warm=True)
        served: float
        future: tuple[float, ...]
        served, future = finish_window(step, min(step + window_steps, horizon), warmed_remaining, warmed_resets)
        warmed: tuple[float, tuple[float, ...]] = served, (at, *future)
        limit: float = suffix[step]

        for position, cost in enumerate(costs[1:], 1):
            reset = resets[position]
            if cost is not None and ((reset is not None and reset >= now + horizon * SLOT_LENGTH) or (reset is None and lengths[position] >= (horizon - step) * SLOT_LENGTH)):
                limit = min(limit, remaining[position] / cost)

        if demand[step] > 0 or round(served, 6) >= round(limit, 6):
            return warmed

        waiting: tuple[float, tuple[float, ...]] = continue_plan(step + 1, remaining, resets)

        return warmed if round(warmed[0], 6) >= round(waiting[0], 6) else waiting

    options: list[float | None] = [now + step * SLOT_LENGTH for step in range(window_steps + 1)] + [None] if initial_resets[0] is None else [None]
    plans: dict[float | None, tuple[float, ...]] = {}
    future: tuple[float, ...]

    for start in options:
        remaining: list[float] = list(initial_remaining)
        resets: list[float | None] = list(initial_resets)
        running: bool = resets[0] is not None
        first: tuple[float, ...] = ()

        for step in range(horizon):
            at: float = now + step * SLOT_LENGTH
            advance_pool(lengths, remaining, resets, at)
            if running and resets[0] is None:
                _, future = continue_plan(step, remaining, resets)
                plans[start] = first + future

                break

            if not running and start is not None and start <= at:
                advance_pool(lengths, remaining, resets, at, warm=True)
                if resets[0] is not None:
                    first = (at,)

            spend_pool(lengths, remaining, resets, costs, demand[step], at)
            running = resets[0] is not None
        else:
            plans[start] = first

    return plans


def simulate_serving(simulation: dict[str, Any], plans: tuple[tuple[float, ...], ...], demands: dict[str, list[float]], now: float, *, offered: list[list[float]] | None = None) -> float:
    lengths: list[list[int]] = simulation["lengths"]
    costs: list[list[float | None]] = simulation["costs"]
    resets: list[list[float | None]] = [list(pool) for pool in simulation["resets"]]
    remaining: list[list[float]] = [list(pool) for pool in simulation["remaining"]]
    cursors: list[int] = [0] * len(plans)
    served: float = 0

    for step in range(PLAN_HORIZON // SLOT_LENGTH):
        at: float = now + step * SLOT_LENGTH

        for index, plan in enumerate(plans):
            cursor: int = cursors[index]
            while cursors[index] < len(plan) and plan[cursors[index]] <= at:
                cursors[index] += 1

            advance_pool(lengths[index], remaining[index], resets[index], at, warm=cursors[index] > cursor)

        # priorities belong to accounts, so both antigravity pools must see the same cold-binding order
        accounts: list[list[int]] = sorted(simulation["accounts"], key=lambda account: rank_resets(resets[index][0] for index in account))
        order: dict[int, int] = {index: position for position, account in enumerate(accounts) for index in account}

        for group, indexes in simulation["groups"].items():
            demand: float = demands[group][step]
            if demand <= 0:
                continue

            for index in sorted(indexes, key=order.__getitem__):
                if offered is not None:
                    offered[index][step] = demand

                spent: float = spend_pool(lengths[index], remaining[index], resets[index], costs[index], demand, at)
                demand -= spent
                served += spent
                if demand <= 0:
                    break

    return served


def plan_warmups(members: list[dict[str, Any]], demands: dict[str, list[float]], budgets: dict[str, dict[str, list[float]]], now: float) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    members = sorted(members, key=lambda entry: (entry["account"]["auth_index"], entry["pool"]["name"] or ""))
    simulation: dict[str, Any] = prepare_simulation(members, budgets, now)
    idle: list[int] = [index for index, pool in enumerate(simulation["resets"]) if pool[0] is None]
    candidates: list[dict[float | None, tuple[float, ...]]] = [plan_pool(simulation, index, demands[find_group(member)], now) if idle else {None: ()} for index, member in enumerate(members)]
    scores: dict[tuple[tuple[float, ...], ...], float] = {}

    def rank(plans: tuple[tuple[float, ...], ...]) -> tuple[float, tuple[tuple[float, ...], ...]]:
        if plans not in scores:
            scores[plans] = round(simulate_serving(simulation, plans, demands, now), 6)

        return -scores[plans], tuple(plan or (math.inf,) for plan in plans)

    waiting: tuple[tuple[float, ...], ...] = tuple(pool[None] for pool in candidates)
    immediate: tuple[tuple[float, ...], ...] = tuple(pool[now] if index in idle else pool[None] for index, pool in enumerate(candidates))
    natural: tuple[tuple[float, ...], ...] = ((),) * len(members)
    best: tuple[tuple[float, ...], ...] = min((waiting, immediate, natural), key=rank)

    if idle:
        for _ in range(2):
            previous: tuple[tuple[float, ...], ...] = best

            # plan against the demand left by earlier accounts; accept changes only by their joint score
            for index in range(len(members)):
                offered: list[list[float]] = [[0] * (PLAN_HORIZON // SLOT_LENGTH) for _ in members]
                simulate_serving(simulation, best, demands, now, offered=offered)
                alternatives: dict[float | None, tuple[float, ...]] = plan_pool(simulation, index, offered[index], now)

                for start, plan in alternatives.items():
                    proposal: tuple[tuple[float, ...], ...] = best[:index] + (plan,) + best[index + 1:]
                    retained: tuple[tuple[float, ...], ...] = best[:index] + (candidates[index][start],) + best[index + 1:]
                    if rank(proposal) < rank(retained):
                        candidates[index][start] = plan

                best = min((best, *(best[:index] + (plan,) + best[index + 1:] for plan in candidates[index].values())), key=rank)

            for left, right in itertools.combinations(idle, 2):
                best = min((best, *(best[:left] + (first,) + best[left + 1:right] + (second,) + best[right + 1:] for first, second in itertools.product(candidates[left].values(), candidates[right].values()))), key=rank)

            if best == previous:
                break

    warmed: list[dict[str, Any]] = []
    planned_starts: list[dict[str, Any]] = []

    for index in idle:
        plan: tuple[float, ...] = best[index]
        if plan and plan[0] == now and is_warmable(members[index]):
            warmed.append(members[index])

        planned_starts.append({"account": members[index]["account"]["auth_index"], "group": find_group(members[index]), "seconds": plan[0] - now if plan else None})

    decision: dict[str, Any] = {
        "provider": members[0]["account"]["provider"],
        "starts_in": planned_starts,
        "served": scores[best],
        "immediate": scores[immediate],
        "waiting": scores[waiting],
        "natural": scores[natural],
        "evaluations": len(scores),
        "uncalibrated": sum(cost is None for pool in simulation["costs"] for cost in pool[1:]),
    }

    return warmed, decision


def rank_spending(entries: list[dict[str, Any]]) -> tuple[int, float]:
    reset: float = rank_resets(entry["window"]["resets_at"] for entry in entries if entry["window"] is not None and not is_idle(entry["window"], entry["fetched_at"]))
    if reset < math.inf:
        return 0, reset

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
        names.sort(key=lambda name: (rank_spending(accounts[name]), accounts[name][0]["account"]["auth_index"]))

        # cliproxyapi spends the highest priority first; a session stays on its account until it is spent
        for position, name in enumerate(names):
            priority: int = len(names) - position

            if priorities.get(name) != priority:
                await call_management("PATCH", "/auth-files/fields", {"name": name, "priority": priority})
                priorities[name] = priority


async def fetch_entries(accounts: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], set[str]]:
    entries: list[dict[str, Any]] = []
    failed: set[str] = set()

    for account in accounts:
        if account["disabled"]:
            continue

        try:
            pools: list[dict[str, Any]] = await FETCHERS[account["provider"]](account)
        except ACCOUNT_ERRORS as error:
            print_account_error(account, error)
            failed.add(account["provider"])

            continue

        fetched_at: float = time.time()

        for pool in pools:
            window: dict[str, Any] | None = next((window for window in pool["windows"] if window["length"] == WINDOW_LENGTHS["5h"]), None)

            entries.append({"account": account, "pool": pool, "window": window, "fetched_at": fetched_at})

    return entries, failed


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

    budgets: dict[str, dict[str, list[float]]] = json.loads(BUDGET_PATH.read_text()) if BUDGET_PATH.exists() else {}
    previous: dict[str, list[dict[str, Any]]] = {}
    priorities: dict[str, int] = {}
    entries: list[dict[str, Any]]
    failed: set[str]
    warm: list[dict[str, Any]]
    decision: dict[str, Any]

    while True:
        entries, failed = await fetch_entries((await call_management("GET", "/auth-files"))["files"])
        now: float = time.time()
        groups: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
        providers: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)

        for entry in entries:
            if entry["window"] is not None:
                groups[find_group(entry)].append(entry)
                providers[entry["account"]["provider"]].append(entry)

        demands: dict[str, list[float]] = {}

        for key, members in groups.items():
            observation: dict[str, Any] = {"observation": "incomplete"} if members[0]["account"]["provider"] in failed else learn_demand(profiles[key], members, previous.get(key, []), budgets)
            report({"group": key, **observation})
            demands[key] = [forecast_demand(profiles[key], now + step * SLOT_LENGTH, now) for step in range(PLAN_HORIZON // SLOT_LENGTH)]

        for members in providers.values():
            warm, decision = plan_warmups(members, demands, budgets, now)
            report(decision)

            for member in warm:
                await warm_pool(member)

        write_state(DEMAND_PATH, dict(profiles))
        write_state(BUDGET_PATH, budgets)

        # the windows longer than 5h start as soon as they can: an hour of them idle is an hour lost
        for entry in entries:
            if has_idle_longer_window(entry) and is_warmable(entry):
                await warm_pool(entry)

        await route_spending(entries, priorities)
        previous = {key: members for key, members in groups.items() if members[0]["account"]["provider"] not in failed}

        resets: list[float] = [window["resets_at"] for entry in entries for window in entry["pool"]["windows"] if window["resets_at"] is not None]
        next_reset: float = min((reset for reset in resets if reset > now), default=now + POLL_INTERVAL)

        await asyncio.sleep(min(next_reset - now + RESET_DELAY, POLL_INTERVAL))


def main() -> None:
    asyncio.run(warm_quotas())


if __name__ == "__main__":
    main()
