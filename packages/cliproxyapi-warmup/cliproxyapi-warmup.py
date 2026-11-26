import asyncio
import itertools
import json
import math
import os
import sys
import time
from collections import defaultdict
from collections.abc import Callable, Coroutine, Iterable
from dataclasses import dataclass
from enum import IntEnum
from functools import cache
from pathlib import Path
from typing import Any, NamedTuple, Self

from cliproxyapi_accounts import (
    ACCOUNT_ERRORS,
    FETCHERS,
    WINDOW_LENGTHS,
    call_management,
    print_account_error,
    send_provider_request,
)

LOW_PRIORITY_ACCOUNTS: dict[str, list[str]] = json.loads(os.environ["CLIPROXYAPI_LOW_PRIORITY_ACCOUNTS"])

POLL_INTERVAL: float = 300  # banked and early resets come unannounced

RESET_TOLERANCE: float = 60  # claude reports the same reset up to a second apart between polls
RESET_DELAY: float = 5  # a window read right at its reset may still show the old one

SLOT_LENGTH: int = 900
WEEK_SLOTS: int = 7 * 86400 // SLOT_LENGTH
DEMAND_HALF_LIFE: float = 14 * 86400  # habits drift; two-week-old demand counts half
SAME_WEEKDAY_WEIGHT: float = 6  # a weekday's own history weighs as much as the other six days together
PLAN_HORIZON: int = 86400

DEMAND_PATH: Path = Path(os.environ["STATE_DIRECTORY"]) / "demand.json"
BUDGET_PATH: Path = DEMAND_PATH.with_name("budgets.json")


def write_state(path: Path, *, state: dict[str, Any]) -> None:
    # a partial json file cannot be loaded on restart; write a copy and replace the old file atomically
    staged: Path = path.with_suffix(".tmp")
    staged.write_text(json.dumps(state))
    staged.replace(path)


def report(event: dict[str, Any]) -> None:
    print(json.dumps(event), file=sys.stderr)


async def warm_claude(account: dict[str, Any], *, pool: str | None) -> None:
    await send_provider_request(
        account,
        method="POST",
        url="https://api.anthropic.com/v1/messages",
        headers={"Content-Type": "application/json", "anthropic-version": "2023-06-01", "anthropic-beta": "oauth-2025-04-20"},
        data=json.dumps({"model": "claude-haiku-4-5", "max_tokens": 1, "messages": [{"role": "user", "content": "hi"}]}),
    )


async def warm_codex(account: dict[str, Any], *, pool: str | None) -> None:
    await send_provider_request(
        account,
        method="POST",
        url="https://chatgpt.com/backend-api/codex/responses",
        headers={"Content-Type": "application/json"},
        data=json.dumps({"model": "gpt-6-luna", "input": [{"role": "user", "content": "hi"}], "store": False, "stream": True}),  # codex answers 400 unless streamed and unstored
    )


# one minimal request starts every window of the pool it is spent from
WARMERS: dict[str, Callable[..., Coroutine[Any, Any, None]]] = {
    "claude": warm_claude,
    "codex": warm_codex,
}


def join_names(*names: str | None) -> str:
    return " ".join(name for name in names if name)


def is_idle(window: dict[str, Any], *, fetched_at: float) -> bool:
    return window["resets_at"] is None or window["resets_at"] <= fetched_at


def is_warmable(entry: dict[str, Any]) -> bool:
    # a request gets 429 while some window of the pool is spent
    return all(window["remaining"] > 0 for window in entry["pool"]["windows"])


def has_idle_longer_window(entry: dict[str, Any]) -> bool:
    # an idle 5h window waits for its group's plan
    if entry["window"] is not None and is_idle(entry["window"], fetched_at=entry["fetched_at"]):
        return False

    return any(is_idle(window, fetched_at=entry["fetched_at"]) for window in entry["pool"]["windows"])


def find_entry_id(entry: dict[str, Any]) -> tuple[str, str | None]:
    return entry["account"]["auth_index"], entry["pool"]["name"]


def find_group(entry: dict[str, Any]) -> str:
    return join_names(entry["account"]["provider"], entry["pool"]["name"])


def find_slot(at: float) -> int:
    moment: time.struct_time = time.gmtime(at)  # the accounts are shared, no one's zone fits; a DST switch shifts the learned demand by an hour until it is relearned

    return (moment.tm_wday * 86400 + moment.tm_hour * 3600 + moment.tm_min * 60) // SLOT_LENGTH


def decay(weight: float, *, since: float, now: float) -> float:
    return weight * 0.5 ** ((now - since) / DEMAND_HALF_LIFE)


def record_demand(profile: list[list[float]], *, at: float, spent: float, duration: float) -> None:
    slot: int = find_slot(at)
    slot_spent, slot_duration, updated_at = profile[slot]

    profile[slot] = [decay(slot_spent, since=updated_at, now=at) + spent, decay(slot_duration, since=updated_at, now=at) + duration, at]


def forecast_demand(profile: list[list[float]], *, at: float, now: float) -> float:
    slot: int = find_slot(at)
    spent: float = 0
    duration: float = 0

    for day in range(7):
        day_spent, day_duration, updated_at = profile[(slot + day * WEEK_SLOTS // 7) % WEEK_SLOTS]
        weight: float = decay(SAME_WEEKDAY_WEIGHT if day == 0 else 1, since=updated_at, now=now)

        spent += weight * day_spent
        duration += weight * day_duration

    return spent / duration * SLOT_LENGTH if duration else 0  # nothing learned yet plans plain chaining


def crossed_reset(*, before: dict[str, Any], entry: dict[str, Any]) -> bool:
    windows: dict[int, dict[str, Any]] = {window["length"]: window for window in entry["pool"]["windows"]}

    for old in before["pool"]["windows"]:
        if is_idle(old, fetched_at=before["fetched_at"]):
            continue

        reset: float | None = windows[old["length"]]["resets_at"]
        if old["resets_at"] <= entry["fetched_at"] or reset is None or abs(reset - old["resets_at"]) >= RESET_TOLERANCE:
            return True

    return False


def measure_spending(*, before: dict[str, Any], window: dict[str, Any]) -> float:
    return max(before["remaining"] - window["remaining"], 0)


def learn_budget(*, before: dict[str, Any], entry: dict[str, Any], budgets: dict[str, dict[str, list[float]]]) -> None:
    windows: dict[int, dict[str, Any]] = {window["length"]: window for window in before["pool"]["windows"]}
    short_spent: float = measure_spending(before=before["window"], window=entry["window"])
    at: float = entry["fetched_at"]

    for window in entry["pool"]["windows"]:
        if window["length"] == WINDOW_LENGTHS["5h"]:
            continue

        spent: float = measure_spending(before=windows[window["length"]], window=window)
        if not short_spent and not spent:
            continue

        profile: dict[str, list[float]] = budgets.setdefault(join_names(*find_entry_id(entry)), {})
        key: str = str(window["length"])
        short_total, total, updated_at = profile.get(key, [0, 0, at])

        # sum the measured changes before dividing; individual rounded deltas often have a zero denominator
        profile[key] = [decay(short_total, since=updated_at, now=at) + short_spent, decay(total, since=updated_at, now=at) + spent, at]


def learn_demand(*, profile: list[list[float]], members: list[dict[str, Any]], previous: list[dict[str, Any]], budgets: dict[str, dict[str, list[float]]]) -> dict[str, Any]:
    before: dict[tuple[str, str | None], dict[str, Any]] = {find_entry_id(entry): entry for entry in previous}
    if before.keys() != {find_entry_id(entry) for entry in members}:
        return {"observation": "baseline"}

    stable: list[dict[str, Any]] = [entry for entry in members if not crossed_reset(before=before[find_entry_id(entry)], entry=entry)]

    for entry in stable:
        learn_budget(before=before[find_entry_id(entry)], entry=entry, budgets=budgets)

    if len(stable) != len(members):
        return {"observation": "reset"}

    duration: float = sum(entry["fetched_at"] - before[find_entry_id(entry)]["fetched_at"] for entry in members) / len(members)
    spent: float = sum(measure_spending(before=before[find_entry_id(entry)]["window"], window=entry["window"]) for entry in members)

    # exhausted limits hide unmet demand; exclude intervals without an available account
    if not any(is_warmable(entry) for entry in previous) or not any(is_warmable(entry) for entry in members):
        return {"observation": "unavailable", "duration": duration, "spent": spent}

    record_demand(profile, at=members[0]["fetched_at"] - duration / 2, spent=spent, duration=duration)

    return {"observation": "measured", "duration": duration, "spent": spent}


def rank_resets(resets: Iterable[float | None]) -> float:
    return min((reset for reset in resets if reset is not None), default=math.inf)


@dataclass(frozen=True, slots=True, kw_only=True)
class Pool:
    lengths: tuple[int, ...]
    costs: tuple[float | None, ...]


@dataclass(slots=True, kw_only=True)
class PoolState:
    remaining: list[float]
    resets: list[float | None]

    def copy(self) -> Self:
        return type(self)(remaining=list(self.remaining), resets=list(self.resets))


@dataclass(frozen=True, slots=True, kw_only=True)
class Simulation:
    pools: list[Pool]
    initial: list[PoolState]
    accounts: list[list[int]]
    groups: dict[str, list[int]]


def prepare_simulation(*, members: list[dict[str, Any]], budgets: dict[str, dict[str, list[float]]], now: float) -> Simulation:
    pools: list[Pool] = []
    initial: list[PoolState] = []
    accounts: defaultdict[str, list[int]] = defaultdict(list)
    groups: defaultdict[str, list[int]] = defaultdict(list)

    for index, member in enumerate(members):
        windows: list[dict[str, Any]] = [member["window"], *(window for window in member["pool"]["windows"] if window["length"] != WINDOW_LENGTHS["5h"])]
        profile: dict[str, list[float]] = budgets.get(join_names(*find_entry_id(member)), {})
        costs: list[float | None] = [1]

        for window in windows[1:]:
            short_total, total, _ = profile.get(str(window["length"]), [0, 0, 0])
            costs.append(total / short_total if short_total > 0 and total > 0 else None)

        pools.append(Pool(lengths=tuple(window["length"] for window in windows), costs=tuple(costs)))
        initial.append(PoolState(remaining=[100 if is_idle(window, fetched_at=now) else window["remaining"] for window in windows], resets=[None if is_idle(window, fetched_at=now) else window["resets_at"] for window in windows]))
        accounts[member["account"]["auth_index"]].append(index)
        groups[find_group(member)].append(index)

    return Simulation(pools=pools, initial=initial, accounts=list(accounts.values()), groups=dict(groups))


def advance_pool(*, pool: Pool, state: PoolState, at: float, warm: bool = False) -> None:
    for position, reset in enumerate(state.resets):
        if reset is not None and reset <= at:
            state.resets[position] = None
            state.remaining[position] = 100

    if not all(value > 0 for value in state.remaining):
        return

    if state.resets[0] is None and warm:
        state.resets[0] = at + pool.lengths[0]

    if state.resets[0] is not None:
        for position, reset in enumerate(state.resets):
            if reset is None:
                state.resets[position] = at + pool.lengths[position]


def spend_pool(*, pool: Pool, state: PoolState, demand: float, at: float) -> float:
    if not all(value > 0 for value in state.remaining):
        return 0

    available: float = min(value / cost for value, cost in zip(state.remaining, pool.costs) if cost is not None)
    spent: float = min(demand, available)
    if spent <= 0:
        return 0

    advance_pool(pool=pool, state=state, at=at, warm=True)

    for position, cost in enumerate(pool.costs):
        if cost is not None:
            state.remaining[position] = max(state.remaining[position] - spent * cost, 0)

    return spent


def plan_pool(*, pool: Pool, initial: PoolState, demand: list[float], now: float) -> dict[float | None, tuple[float, ...]]:
    horizon: int = len(demand)
    window_steps: int = math.ceil(pool.lengths[0] / SLOT_LENGTH)
    suffix: list[float] = [0] * (horizon + 1)

    for step in range(horizon - 1, -1, -1):
        suffix[step] = suffix[step + 1] + demand[step]

    def continue_plan(*, step: int, state: PoolState) -> tuple[float, tuple[float, ...]]:
        capacity: float = min(suffix[step], 100 * (math.ceil((horizon - step) / window_steps) + 1))

        # merge nonbinding budgets to avoid searching equivalent window schedules
        for position, cost in enumerate(pool.costs[1:], 1):
            if state.remaining[position] > 0 and (cost is None or state.remaining[position] / cost >= capacity):
                state.remaining[position] = 100
                state.resets[position] = now + PLAN_HORIZON + pool.lengths[position]

        return solve(step=step, balances=tuple(state.remaining), deadlines=tuple(state.resets))

    def finish_window(*, step: int, end: int, state: PoolState) -> tuple[float, tuple[float, ...]]:
        served: float = 0

        for tick in range(step, end):
            at: float = now + tick * SLOT_LENGTH
            advance_pool(pool=pool, state=state, at=at)
            served += spend_pool(pool=pool, state=state, demand=demand[tick], at=at)

        future: float
        plan: tuple[float, ...]
        future, plan = continue_plan(step=end, state=state)

        return served + future, plan

    # choose later starts at each reset so the forecast includes shifts across quiet gaps
    @cache
    def solve(*, step: int, balances: tuple[float, ...], deadlines: tuple[float | None, ...]) -> tuple[float, tuple[float, ...]]:
        if step >= horizon:
            return 0, ()

        at: float = now + step * SLOT_LENGTH
        state: PoolState = PoolState(remaining=list(balances), resets=list(deadlines))
        advance_pool(pool=pool, state=state, at=at)
        reset: float | None = state.resets[0]
        if reset is not None:
            return finish_window(step=step, end=min(math.ceil((reset - now) / SLOT_LENGTH), horizon), state=state)

        if not all(value > 0 for value in state.remaining):
            return continue_plan(step=step + 1, state=state)

        warmed_state: PoolState = state.copy()
        advance_pool(pool=pool, state=warmed_state, at=at, warm=True)
        served: float
        future: tuple[float, ...]
        served, future = finish_window(step=step, end=min(step + window_steps, horizon), state=warmed_state)
        warmed: tuple[float, tuple[float, ...]] = served, (at, *future)
        limit: float = suffix[step]

        for position, cost in enumerate(pool.costs[1:], 1):
            reset = state.resets[position]
            if cost is not None and ((reset is not None and reset >= now + horizon * SLOT_LENGTH) or (reset is None and pool.lengths[position] >= (horizon - step) * SLOT_LENGTH)):
                limit = min(limit, state.remaining[position] / cost)

        if demand[step] > 0 or round(served, 6) >= round(limit, 6):
            return warmed

        waiting: tuple[float, tuple[float, ...]] = continue_plan(step=step + 1, state=state)

        return warmed if round(warmed[0], 6) >= round(waiting[0], 6) else waiting

    options: list[float | None] = [now + step * SLOT_LENGTH for step in range(window_steps + 1)] + [None] if initial.resets[0] is None else [None]
    plans: dict[float | None, tuple[float, ...]] = {}
    future: tuple[float, ...]

    for start in options:
        state: PoolState = initial.copy()
        running: bool = state.resets[0] is not None
        first: tuple[float, ...] = ()

        for step in range(horizon):
            at: float = now + step * SLOT_LENGTH
            advance_pool(pool=pool, state=state, at=at)
            if running and state.resets[0] is None:
                _, future = continue_plan(step=step, state=state)
                plans[start] = first + future

                break

            if not running and start is not None and start <= at:
                advance_pool(pool=pool, state=state, at=at, warm=True)
                if state.resets[0] is not None:
                    first = (at,)

            spend_pool(pool=pool, state=state, demand=demand[step], at=at)
            running = state.resets[0] is not None
        else:
            plans[start] = first

    return plans


class ShortWindow(IntEnum):
    RUNNING = 0
    ABSENT = 1
    IDLE = 2


class SpendingRank(NamedTuple):
    spent: bool
    weekly_reset: float
    short_window: ShortWindow
    short_reset: float


# the order `rank_spending` gives the accounts, in the simulated state
def rank_simulated_spending(account: list[int], *, states: list[PoolState]) -> SpendingRank:
    spent: bool = not any(all(value > 0 for value in states[index].remaining) for index in account)
    weekly: float = rank_resets(reset for index in account for reset in states[index].resets[1:])

    reset: float = rank_resets(states[index].resets[0] for index in account)
    if reset < math.inf:
        return SpendingRank(spent=spent, weekly_reset=weekly, short_window=ShortWindow.RUNNING, short_reset=reset)

    return SpendingRank(spent=spent, weekly_reset=weekly, short_window=ShortWindow.IDLE, short_reset=0)


def simulate_serving(*, simulation: Simulation, plans: tuple[tuple[float, ...], ...], demands: dict[str, list[float]], now: float, offered: list[list[float]] | None = None) -> float:
    states: list[PoolState] = [state.copy() for state in simulation.initial]
    cursors: list[int] = [0] * len(plans)
    served: float = 0

    for step in range(PLAN_HORIZON // SLOT_LENGTH):
        at: float = now + step * SLOT_LENGTH

        for index, plan in enumerate(plans):
            cursor: int = cursors[index]
            while cursors[index] < len(plan) and plan[cursors[index]] <= at:
                cursors[index] += 1

            advance_pool(pool=simulation.pools[index], state=states[index], at=at, warm=cursors[index] > cursor)

        # priorities belong to accounts, so every pool of an account must see the same cold-binding order
        accounts: list[list[int]] = sorted(simulation.accounts, key=lambda account: rank_simulated_spending(account, states=states))
        order: dict[int, int] = {index: position for position, account in enumerate(accounts) for index in account}

        for group, indexes in simulation.groups.items():
            demand: float = demands[group][step]
            if demand <= 0:
                continue

            for index in sorted(indexes, key=order.__getitem__):
                if offered is not None:
                    offered[index][step] = demand

                spent: float = spend_pool(pool=simulation.pools[index], state=states[index], demand=demand, at=at)
                demand -= spent
                served += spent
                if demand <= 0:
                    break

    return served


def plan_warmups(*, members: list[dict[str, Any]], demands: dict[str, list[float]], budgets: dict[str, dict[str, list[float]]], now: float) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    members = sorted(members, key=lambda entry: (entry["account"]["auth_index"], entry["pool"]["name"] or ""))
    simulation: Simulation = prepare_simulation(members=members, budgets=budgets, now=now)
    idle: list[int] = [index for index, state in enumerate(simulation.initial) if state.resets[0] is None]
    candidates: list[dict[float | None, tuple[float, ...]]] = [plan_pool(pool=simulation.pools[index], initial=simulation.initial[index], demand=demands[find_group(member)], now=now) if idle else {None: ()} for index, member in enumerate(members)]
    scores: dict[tuple[tuple[float, ...], ...], float] = {}

    def rank(plans: tuple[tuple[float, ...], ...]) -> tuple[float, tuple[tuple[float, ...], ...]]:
        if plans not in scores:
            scores[plans] = round(simulate_serving(simulation=simulation, plans=plans, demands=demands, now=now), 6)

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
                simulate_serving(simulation=simulation, plans=best, demands=demands, now=now, offered=offered)
                alternatives: dict[float | None, tuple[float, ...]] = plan_pool(pool=simulation.pools[index], initial=simulation.initial[index], demand=offered[index], now=now)

                for start, plan in alternatives.items():
                    proposal: tuple[tuple[float, ...], ...] = best[:index] + (plan,) + best[index + 1 :]
                    retained: tuple[tuple[float, ...], ...] = best[:index] + (candidates[index][start],) + best[index + 1 :]
                    if rank(proposal) < rank(retained):
                        candidates[index][start] = plan

                best = min((best, *(best[:index] + (plan,) + best[index + 1 :] for plan in candidates[index].values())), key=rank)

            for left, right in itertools.combinations(idle, 2):
                best = min((best, *(best[:left] + (first,) + best[left + 1 : right] + (second,) + best[right + 1 :] for first, second in itertools.product(candidates[left].values(), candidates[right].values()))), key=rank)

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
        "uncalibrated": sum(cost is None for pool in simulation.pools for cost in pool.costs[1:]),
    }

    return warmed, decision


def rank_spending(entries: list[dict[str, Any]]) -> SpendingRank:
    spent: bool = not any(is_warmable(entry) for entry in entries)

    # quota left at a reset is lost; the account whose weekly window resets first is spent first
    weekly: float = rank_resets(window["resets_at"] for entry in entries for window in entry["pool"]["windows"] if window["length"] != WINDOW_LENGTHS["5h"] and not is_idle(window, fetched_at=entry["fetched_at"]))

    reset: float = rank_resets(entry["window"]["resets_at"] for entry in entries if entry["window"] is not None and not is_idle(entry["window"], fetched_at=entry["fetched_at"]))
    if reset < math.inf:
        return SpendingRank(spent=spent, weekly_reset=weekly, short_window=ShortWindow.RUNNING, short_reset=reset)

    # an idle 5h window waits for its planned start behind accounts that have none
    if all(entry["window"] is None for entry in entries):
        return SpendingRank(spent=spent, weekly_reset=weekly, short_window=ShortWindow.ABSENT, short_reset=0)

    return SpendingRank(spent=spent, weekly_reset=weekly, short_window=ShortWindow.IDLE, short_reset=0)


def is_free(account: dict[str, Any]) -> bool:
    return account["provider"] == "codex" and account["id_token"]["plan_type"] == "free"


async def route_spending(*, entries: list[dict[str, Any]], priorities: dict[str, int]) -> None:
    accounts: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)

    for entry in entries:
        accounts[entry["account"]["name"]].append(entry)

    providers: defaultdict[str, list[str]] = defaultdict(list)
    next_priorities: dict[str, int] = {}

    for name, account_entries in accounts.items():
        account: dict[str, Any] = account_entries[0]["account"]

        low_priority_accounts: list[str] = LOW_PRIORITY_ACCOUNTS.get(account["provider"], [])

        if account["email"] in low_priority_accounts:
            next_priorities[name] = -low_priority_accounts.index(account["email"])  # each one is spent only after the one before it
        else:
            providers[account["provider"]].append(name)

    for names in providers.values():
        # free accounts are disposable; spend them before paid subscriptions
        names.sort(key=lambda name: (not is_free(accounts[name][0]["account"]), rank_spending(accounts[name]), accounts[name][0]["account"]["auth_index"]))

        # cliproxyapi spends the highest priority first; a session stays on its account until it is spent
        next_priorities.update({name: len(names) - position for position, name in enumerate(names)})

    for name, priority in next_priorities.items():
        if priorities.get(name) != priority:
            await call_management(method="PATCH", path="/auth-files/fields", payload={"name": name, "priority": priority})
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
            print_account_error(account, error=error)
            failed.add(account["provider"])

            continue

        fetched_at: float = time.time()

        for pool in pools:
            window: dict[str, Any] | None = next((window for window in pool["windows"] if window["length"] == WINDOW_LENGTHS["5h"]), None)

            entries.append({"account": account, "pool": pool, "window": window, "fetched_at": fetched_at})

    return entries, failed


async def warm_pool(entry: dict[str, Any]) -> None:
    # a window may reset between the fetch and the warmup
    idle: list[dict[str, Any]] = [window for window in entry["pool"]["windows"] if is_idle(window, fetched_at=time.time())]
    labels: str = ", ".join(window["label"] for window in idle)

    try:
        await WARMERS[entry["account"]["provider"]](entry["account"], pool=entry["pool"]["name"])
    except ACCOUNT_ERRORS as error:
        print_account_error(entry["account"], error=error)

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
        entries, failed = await fetch_entries((await call_management(method="GET", path="/auth-files"))["files"])
        now: float = time.time()
        groups: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
        providers: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)

        for entry in entries:
            if entry["window"] is not None:
                groups[find_group(entry)].append(entry)
                providers[entry["account"]["provider"]].append(entry)

        demands: dict[str, list[float]] = {}

        for key, members in groups.items():
            observation: dict[str, Any] = {"observation": "incomplete"} if members[0]["account"]["provider"] in failed else learn_demand(profile=profiles[key], members=members, previous=previous.get(key, []), budgets=budgets)
            report({"group": key, **observation})
            demands[key] = [forecast_demand(profiles[key], at=now + step * SLOT_LENGTH, now=now) for step in range(PLAN_HORIZON // SLOT_LENGTH)]

        for members in providers.values():
            warm, decision = plan_warmups(members=members, demands=demands, budgets=budgets, now=now)
            report(decision)

            for member in warm:
                await warm_pool(member)

        write_state(DEMAND_PATH, state=dict(profiles))
        write_state(BUDGET_PATH, state=budgets)

        # the windows longer than 5h start as soon as they can: an hour of them idle is an hour lost
        for entry in entries:
            if has_idle_longer_window(entry) and is_warmable(entry):
                await warm_pool(entry)

        await route_spending(entries=entries, priorities=priorities)
        previous = {key: members for key, members in groups.items() if members[0]["account"]["provider"] not in failed}

        resets: list[float] = [window["resets_at"] for entry in entries for window in entry["pool"]["windows"] if window["resets_at"] is not None]
        next_reset: float = min((reset for reset in resets if reset > now), default=now + POLL_INTERVAL)

        await asyncio.sleep(min(next_reset - now + RESET_DELAY, POLL_INTERVAL))


def main() -> None:
    asyncio.run(warm_quotas())


if __name__ == "__main__":
    main()
