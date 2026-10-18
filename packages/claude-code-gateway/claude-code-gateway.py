import asyncio
import datetime
import json
import os
import re
import time
from collections.abc import Callable
from typing import Any

import aiohttp
from aiohttp import web
from cliproxyapi_accounts import (
    ACCOUNT_ERRORS,
    CLIPROXYAPI_TIMEOUT,
    CLIPROXYAPI_URL,
    FETCHERS,
    call_management,
    format_window_length,
    print_account_error,
    read_key,
)

HOST: str = os.environ["CLAUDE_CODE_GATEWAY_HOST"]
PORT: int = int(os.environ["CLAUDE_CODE_GATEWAY_PORT"])

CLAUDE_CATALOG_URL: str = "https://downloads.claude.ai/model-catalog/v1/catalog.json"  # what claude orders its own picker by

CLOAK_PREFIX: str = "claude-fable-5-dd-"  # cliproxyapi's disguise for foreign ids: claude lists only claude-like ones

BEHAVES_AS: str = "claude-opus-5-5"  # claude knows a foreign model only through a catalog one: set the most capable one claude doesn't gate behind usage credits

TIER_SEPARATOR: str = ":"  # a picker id `codex/gpt-5.5:priority` is the model asked in that service tier

FRAMING_HEADERS: set[str] = {"connection", "content-length", "host", "transfer-encoding"}  # aiohttp frames both directions itself

CLASSIFIER_PROMPT: str = "You are a security monitor for autonomous AI coding agents."  # auto mode's local check, sent when the api gives no verdict of its own

# what each agent checks its actions with: codex the auto-review model of its catalog, antigravity the flash tier
# (the tier's own `gemini-3.8-flash-tiered` is missing from cliproxyapi)
REVIEWERS: dict[str, str] = {
    "codex": "codex/codex-auto-review",
    "antigravity": "antigravity/gemini-3.8-flash-high",
}

QUOTA_MIN_AGE: float = 30  # the status line renders many times per turn
QUOTA_MAX_AGE: float = 300  # the subscriptions are spent outside cliproxyapi too

PICKER_QUOTA_TIMEOUT: float = 2  # the wrapper waits for the picker before claude starts
PICKER_CATALOG_TIMEOUT: float = 2
STATUS_LINE_QUOTA_TIMEOUT: float = 1

refreshes: dict[str, asyncio.Task[None]] = {}

attempted_at: dict[str, float] = {}
snapshots: dict[str, dict[str, Any]] = {}

claude_lineup: dict[str, Any] = {}

session_providers: dict[str, str] = {}


def read_claude_quota(quota: dict[str, Any]) -> list[dict[str, Any]]:
    signals: dict[str, str] = quota["signals"]

    return [
        {
            "label": window,
            "remaining": 100 - float(signals[f"anthropic-ratelimit-unified-{window}-utilization"]) * 100,
            "resets_at": float(signals[f"anthropic-ratelimit-unified-{window}-reset"]),
        }
        for window in ("5h", "7d")
        if f"anthropic-ratelimit-unified-{window}-utilization" in signals
    ]


def read_codex_quota(quota: dict[str, Any]) -> list[dict[str, Any]]:
    signals: dict[str, str] = quota["signals"]
    observed_at: float = datetime.datetime.fromisoformat(quota["observed_at"]).timestamp()

    windows: list[dict[str, Any]] = []

    for name in ("primary", "secondary"):
        if f"x-codex-{name}-used-percent" not in signals:
            continue

        reset_at: str | None = signals.get(f"x-codex-{name}-reset-at")

        windows.append({
            "label": format_window_length(int(signals[f"x-codex-{name}-window-minutes"]) * 60),  # the primary window is 5h on plus, 30d on free
            "remaining": 100 - float(signals[f"x-codex-{name}-used-percent"]),
            "resets_at": float(reset_at) if reset_at else observed_at + float(signals[f"x-codex-{name}-reset-after-seconds"]),
        })

    return windows


# rate limit headers of an account's last answer; cliproxyapi keeps them only for claude and codex
OBSERVERS: dict[str, Callable[[dict[str, Any]], list[dict[str, Any]]]] = {
    "claude": read_claude_quota,
    "codex": read_codex_quota,
}


def is_reset(snapshot: dict[str, Any], now: float) -> bool:
    resets: list[float | None] = [window["resets_at"] for pool in snapshot["pools"] for window in pool["windows"]]

    return any(reset_at is not None and reset_at < now for reset_at in resets)


def is_outdated(account: dict[str, Any], now: float) -> bool:
    snapshot: dict[str, Any] | None = snapshots.get(account["auth_index"])
    if snapshot is None:
        return True

    aged: bool = now - snapshot["fetched_at"] > QUOTA_MAX_AGE

    return snapshot["observed"] or aged or is_reset(snapshot, now)  # a snapshot from headers stands only while `observe_quota` accepts them, then a fetch replaces it


def observe_quota(account: dict[str, Any], now: float) -> bool:
    quota: dict[str, Any] = account["quota"]
    if not quota["signals"]:
        return False

    # the account is spent outside cliproxyapi too; headers of an old answer miss that
    observed_at: float = datetime.datetime.fromisoformat(quota["observed_at"]).timestamp()
    if now - observed_at > QUOTA_MAX_AGE:
        return False

    signals: dict[str, str] = {name.lower(): value for name, value in quota["signals"].items()}

    windows: list[dict[str, Any]] = OBSERVERS[account["provider"]]({**quota, "signals": signals})
    snapshot: dict[str, Any] = {"pools": [{"name": None, "windows": windows}], "fetched_at": observed_at, "observed": True}

    # a lone `retry-after` carries no windows, headers past a reset describe the previous window
    if not windows or is_reset(snapshot, now):
        return False

    snapshots[account["auth_index"]] = snapshot

    return True


async def refresh_quota(account: dict[str, Any], started_at: float) -> None:
    try:
        pools: list[dict[str, Any]] = await FETCHERS[account["provider"]](account)
    except ACCOUNT_ERRORS as error:
        print_account_error(account, error)  # the last known quota stays and gets marked stale

        return

    snapshots[account["auth_index"]] = {"pools": pools, "fetched_at": started_at, "observed": False}


async def read_quotas(timeout: float) -> dict[str, list[dict[str, Any]]]:
    files: list[dict[str, Any]] = (await call_management("GET", "/auth-files"))["files"]
    accounts: list[dict[str, Any]] = [account for account in files if not account["disabled"]]

    now: float = time.time()

    for account in accounts:
        index: str = account["auth_index"]

        observed: bool = account["provider"] in OBSERVERS and observe_quota(account, now)

        if not observed and is_outdated(account, now) and now - attempted_at.get(index, 0) > QUOTA_MIN_AGE:
            attempted_at[index] = now
            refreshes[index] = asyncio.create_task(refresh_quota(account, now))

    pending: list[asyncio.Task[None]] = [refreshes[account["auth_index"]] for account in accounts if account["auth_index"] in refreshes]

    if pending:
        await asyncio.wait(pending, timeout=timeout)

    quotas: dict[str, list[dict[str, Any]]] = {}

    for account in accounts:
        snapshot: dict[str, Any] = snapshots.get(account["auth_index"], {"pools": [{"name": None, "windows": []}], "fetched_at": now})

        quotas.setdefault(account["provider"], []).append({
            "label": account["label"],  # cliproxyapi's name for any account; the email of an oauth one
            # `updated_at` moves on token refreshes too; only an account without rate limit headers falls back to it
            "used_at": datetime.datetime.fromisoformat(account["quota"].get("observed_at") or account["updated_at"]).timestamp(),
            "pools": snapshot["pools"],
            "stale": snapshot["fetched_at"] < attempted_at.get(account["auth_index"], 0) or is_reset(snapshot, now),
        })

    return quotas


def uncloak_model(model_id: str) -> str:
    return model_id.removeprefix(CLOAK_PREFIX)[::-1] if model_id.startswith(CLOAK_PREFIX) else model_id


def split_model(model_id: str) -> tuple[str, str]:
    name: str = uncloak_model(model_id)

    # every account but the claude one carries its provider as the model prefix
    provider, separator, model = name.partition("/")

    return (provider, model) if separator else ("claude", name)


def match_pools(model: str, pools: list[dict[str, Any]]) -> list[dict[str, Any]]:
    matching: list[dict[str, Any]] = [
        pool for pool in pools
        if pool["name"] and any(word in model for word in re.findall(r"[a-z]{3,}", pool["name"].lower()))
    ]

    return matching or pools


def collect_labels(quotas: dict[str, list[dict[str, Any]]]) -> set[str]:
    return {account["label"] for accounts in quotas.values() for account in accounts}


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


async def read_catalog() -> list[dict[str, Any]]:
    headers: dict[str, str] = {"Authorization": f"Bearer {read_key('inference-key')}", "anthropic-version": "2023-06-01"}

    async with (
        aiohttp.ClientSession(timeout=CLIPROXYAPI_TIMEOUT) as client,
        client.get(f"{CLIPROXYAPI_URL}/v1/models", headers=headers) as answer,
    ):
        catalog: dict[str, Any] = await answer.json()

    return catalog["data"]


async def read_service_tiers() -> dict[str, list[dict[str, str]]]:
    headers: dict[str, str] = {"Authorization": f"Bearer {read_key('inference-key')}"}

    # the catalog cliproxyapi gives codex; the claude one doesn't tell which models have a faster tier
    async with (
        aiohttp.ClientSession(timeout=CLIPROXYAPI_TIMEOUT) as client,
        client.get(f"{CLIPROXYAPI_URL}/v1/models", params={"client_version": ""}, headers=headers) as answer,
    ):
        catalog: dict[str, Any] = await answer.json()

    return {model["slug"]: model["service_tiers"] for model in catalog["models"]}


async def read_claude_lineup() -> list[str] | None:
    if claude_lineup and time.time() < claude_lineup["expires_at"]:
        return claude_lineup["models"]

    try:
        async with (
            aiohttp.ClientSession(timeout=aiohttp.ClientTimeout(total=PICKER_CATALOG_TIMEOUT), raise_for_status=True) as client,
            client.get(CLAUDE_CATALOG_URL) as answer,
        ):
            catalog: dict[str, Any] = await answer.json(content_type=None)

        selector: dict[str, Any] = catalog["surfaces"]["cc"]["model_selector_config"][0]

        models: list[str] = [model["id"] for model in selector["models"]]
        expires_at: float = datetime.datetime.fromisoformat(catalog["expires_at"]).timestamp()
    except (aiohttp.ClientError, TimeoutError, LookupError, ValueError):
        return None  # downloaded from claude's servers; the picker keeps cliproxyapi's order without it

    claude_lineup.update(models=models, expires_at=expires_at)

    return models


def order_models(catalog: list[dict[str, Any]], lineup: list[str] | None) -> list[dict[str, Any]]:
    claude: list[dict[str, Any]] = [model for model in catalog if split_model(model["id"])[0] == "claude"]
    if lineup is not None:
        # claude's own order; the claude models it hides stay hidden
        claude = sorted((model for model in claude if model["id"] in lineup), key=lambda model: lineup.index(model["id"]))

    # cliproxyapi interleaves providers; grouped by name, each keeps its own order
    others: list[dict[str, Any]] = sorted((model for model in catalog if split_model(model["id"])[0] != "claude"), key=lambda model: split_model(model["id"])[0])

    return claude + others


def label_model(model: dict[str, Any], tier: dict[str, str] | None) -> str:
    provider, _ = split_model(model["id"])

    label: str = model["display_name"] if provider == "claude" else f"{provider.capitalize()} · {model['display_name']}"

    return label if tier is None else f"{label} {tier['name']}"


def apply_tier(body: bytes) -> bytes:
    payload: dict[str, Any] = json.loads(body)

    model, separator, tier = payload["model"].partition(TIER_SEPARATOR)
    if not separator:
        return body

    # effort stays whatever claude asked, the tier only buys speed
    return json.dumps({**payload, "model": model, "service_tier": tier}).encode()


def route_classifier(session: str, body: bytes) -> bytes:
    payload: dict[str, Any] = json.loads(body)

    # the action under check comes from the answer to the session's latest request with tools
    if payload.get("tools"):
        session_providers[session] = split_model(payload["model"])[0]

        return body

    # the check brings a prompt of its own; the user's text in claude's prompt never leads a block
    classifier: bool = any(block["text"].startswith(CLASSIFIER_PROMPT) for block in payload["system"])
    if not classifier:
        return body

    # claude checks with sonnet whatever proposed the action; a foreign model's own provider pays for it instead
    reviewer: str | None = REVIEWERS.get(session_providers[session])
    if reviewer is None:
        return body

    return json.dumps({**payload, "model": reviewer}).encode()


async def relay(request: web.Request) -> web.StreamResponse:
    # cliproxyapi sees the key only after the whole body is read, and takes relayed calls as local ones,
    # which lets anyone fill the gateway's memory with one huge body or, with five wrong management keys, get 127.0.0.1 banned from management along with the gateway and the warmup;
    # gatus checks `/healthz` without a key
    if request.path != "/healthz" and request.headers.get("Authorization") != f"Bearer {read_key('inference-key')}":
        raise web.HTTPUnauthorized

    body: bytes = await request.read()
    if request.path in {"/v1/messages", "/v1/messages/count_tokens"}:
        body = apply_tier(body)
    if request.path == "/v1/messages":
        body = route_classifier(request.headers["X-Claude-Code-Session-Id"], body)

    headers: list[tuple[str, str]] = [(name, value) for name, value in request.headers.items() if name.lower() not in FRAMING_HEADERS]

    # claude hanging up cancels the handler, which closes the upstream connection;
    # the body stays compressed, as its `content-encoding` says
    async with (
        aiohttp.ClientSession(auto_decompress=False, timeout=aiohttp.ClientTimeout(total=None)) as client,
        client.request(request.method, f"{CLIPROXYAPI_URL}{request.raw_path}", headers=headers, data=body) as answer,
    ):
        response: web.StreamResponse = web.StreamResponse(
            status=answer.status,
            headers=[(name, value) for name, value in answer.headers.items() if name.lower() not in FRAMING_HEADERS],
        )

        await response.prepare(request)

        async for chunk in answer.content.iter_any():
            await response.write(chunk)

        await response.write_eof()

        return response


async def serve_quotas(request: web.Request) -> web.Response:
    if request.headers.get("Authorization") != f"Bearer {read_key('inference-key')}":
        raise web.HTTPUnauthorized

    quotas: dict[str, list[dict[str, Any]]] = await read_quotas(STATUS_LINE_QUOTA_TIMEOUT)

    # picker options append tier and context window suffixes to the model id
    model_id: str = request.query["model"].partition(TIER_SEPARATOR)[0].removesuffix("[1m]")

    provider, model = split_model(model_id)

    accounts: list[dict[str, Any]] = quotas.get(provider, [])

    # session affinity keeps a session on one account, so the latest answered one is the current;
    # before the first answer the session has none yet
    shown: list[dict[str, Any]] = accounts if "all" in request.query else [max(accounts, key=lambda account: account["used_at"])] if accounts else []

    # what is left of the status line; the label shrinks to fit it
    width: int = int(request.query["width"])

    return web.json_response(describe_quota(model, shown, collect_labels(quotas), width))


async def serve_model_picker(request: web.Request) -> web.Response:
    if request.headers.get("Authorization") != f"Bearer {read_key('inference-key')}":
        raise web.HTTPUnauthorized

    models, tiers, quotas, lineup = await asyncio.gather(read_catalog(), read_service_tiers(), read_quotas(PICKER_QUOTA_TIMEOUT), read_claude_lineup())

    catalog: list[dict[str, Any]] = order_models(models, lineup)

    # a faster tier is picked like a model, per session; its rows follow all the plain ones
    rows: list[tuple[dict[str, Any], dict[str, str] | None]] = [
        *((model, None) for model in catalog),
        *((model, tier) for model in catalog for tier in tiers.get(uncloak_model(model["id"]), [])),
    ]

    account_labels: set[str] = collect_labels(quotas)

    labels: list[str] = [label_model(model, tier) for model, tier in rows]

    # a row is the padding, pointer, index, the longest label, the current model's checkmark and the gaps between them;
    # claude puts its "Default (recommended)" row on top of these
    width: int = int(request.query["width"]) - max(map(len, labels)) - len(f"{len(rows) + 1}.") - 12

    options: list[dict[str, str]] = []
    for (model, tier), label in zip(rows, labels, strict=True):
        provider, name = split_model(model["id"])

        # under its own id a foreign model gets its own effort in `modelSettings`, not the one of the disguise
        model_id: str = uncloak_model(model["id"])

        # let claude use antigravity gemini's 1M context only where the catalog advertises it; claude strips `[1m]` before sending the api request
        if provider == "antigravity" and name.startswith("gemini-") and model["max_input_tokens"] >= 1000000:
            model_id = f"{model_id}[1m]"

        option: dict[str, str] = {
            "model": model_id if tier is None else f"{model_id}{TIER_SEPARATOR}{tier['id']}",
            "label": label,
            "description": describe_quota(name, quotas.get(provider, []), account_labels, width),
        }

        if provider != "claude":
            option["behavesAs"] = BEHAVES_AS

        options.append(option)

    # the built-in rows would repeat the claude models of the catalog
    return web.json_response({"modelPicker": {"replaceBuiltInOptions": True, "options": options}})


def main() -> None:
    application: web.Application = web.Application(client_max_size=0)  # prompts with images outgrow the default megabyte

    application.add_routes([
        web.get("/model-picker", serve_model_picker),
        web.get("/quotas", serve_quotas),
        web.route("*", "/{path:.*}", relay),
    ])

    web.run_app(application, host=HOST, port=PORT, handler_cancellation=True)


if __name__ == "__main__":
    main()
