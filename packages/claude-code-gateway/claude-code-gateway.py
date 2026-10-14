import asyncio
import datetime
import json
import os
import re
import sys
import time
from collections.abc import Callable, Coroutine
from typing import Any

import aiohttp
from aiohttp import web

PORT: int = int(os.environ["CLAUDE_CODE_GATEWAY_PORT"])

CLIPROXYAPI_STATE_DIRECTORY: str = os.environ["CLIPROXYAPI_STATE_DIRECTORY"]

CLAUDE_CATALOG_URL: str = "https://downloads.claude.ai/model-catalog/v1/catalog.json"  # what claude orders its own picker by

CLOAK_PREFIX: str = "claude-fable-5-dd-"  # cliproxyapi's disguise for foreign ids: claude lists only claude-like ones

BEHAVES_AS: str = "claude-fable-5"  # what the disguise made of every foreign model

FRAMING_HEADERS: set[str] = {"connection", "content-length", "host", "transfer-encoding"}  # aiohttp frames both directions itself

CLIPROXYAPI_TIMEOUT: aiohttp.ClientTimeout = aiohttp.ClientTimeout(total=10)

QUOTA_MIN_AGE: float = 30  # the status line renders many times per turn
QUOTA_MAX_AGE: float = 300  # other hosts spend the same subscriptions unseen

PICKER_QUOTA_TIMEOUT: float = 2  # claude waits for the picker before it starts
PICKER_CATALOG_TIMEOUT: float = 2
STATUS_LINE_QUOTA_TIMEOUT: float = 1

refreshes: dict[str, asyncio.Task[None]] = {}

attempted_at: dict[str, float] = {}
snapshots: dict[str, dict[str, Any]] = {}

claude_lineup: dict[str, Any] = {}


def read_key(name: str) -> str:
    with open(os.path.join(CLIPROXYAPI_STATE_DIRECTORY, name)) as file:
        return file.read()


def read_upstream() -> str:
    with open(os.path.join(CLIPROXYAPI_STATE_DIRECTORY, "config.yaml")) as file:
        server: dict[str, Any] = json.load(file)["server"]

    return f"http://{server['host']}:{server['port']}"


async def call_management(method: str, path: str, payload: dict[str, Any] | None = None) -> Any:
    headers: dict[str, str] = {"Authorization": f"Bearer {read_key('management-key')}"}

    async with (
        aiohttp.ClientSession(timeout=CLIPROXYAPI_TIMEOUT, raise_for_status=True) as client,
        client.request(method, f"{read_upstream()}/v0/management{path}", json=payload, headers=headers) as answer,
    ):
        return await answer.json()


async def call_provider(account: dict[str, Any], method: str, url: str, headers: dict[str, str], data: str = "") -> Any:
    # cliproxyapi sends the request itself and puts the account's oauth token in place of `$TOKEN$`
    response: dict[str, Any] = await call_management("POST", "/api-call", {
        "auth_index": account["auth_index"],
        "method": method,
        "url": url,
        "header": {"Authorization": "Bearer $TOKEN$", **headers},
        "data": data,
    })

    if response["status_code"] != 200:
        raise RuntimeError(f"{url} answered {response['status_code']}")

    return json.loads(response["body"])


def parse_time(value: str | None) -> float | None:
    if value is None:
        return None

    return datetime.datetime.fromisoformat(value).timestamp()


def format_window(seconds: int) -> str:
    if seconds % 86400 == 0:
        return f"{seconds // 86400}d"

    return f"{seconds // 3600}h"


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
            "label": format_window(int(signals[f"x-codex-{name}-window-minutes"]) * 60),  # which window is the short one depends on the plan
            "remaining": 100 - float(signals[f"x-codex-{name}-used-percent"]),
            "resets_at": float(reset_at) if reset_at else observed_at + float(signals[f"x-codex-{name}-reset-after-seconds"]),
        })

    return windows


async def fetch_claude_quota(account: dict[str, Any]) -> list[dict[str, Any]]:
    usage: dict[str, Any] = await call_provider(account, "GET", "https://api.anthropic.com/api/oauth/usage", {"anthropic-beta": "oauth-2025-04-20"})

    windows: list[dict[str, Any]] = [
        {"label": label, "remaining": 100 - usage[key]["utilization"], "resets_at": parse_time(usage[key]["resets_at"])}
        for key, label in (("five_hour", "5h"), ("seven_day", "7d"))
        if usage.get(key)
    ]

    return [{"name": None, "windows": windows}]


async def fetch_codex_quota(account: dict[str, Any]) -> list[dict[str, Any]]:
    usage: dict[str, Any] = await call_provider(account, "GET", "https://chatgpt.com/backend-api/wham/usage", {"User-Agent": "codex_cli_rs"})

    windows: list[dict[str, Any]] = [
        {"label": format_window(window["limit_window_seconds"]), "remaining": 100 - window["used_percent"], "resets_at": window["reset_at"]}
        for window in (usage["rate_limit"].get("primary_window"), usage["rate_limit"].get("secondary_window"))
        if window
    ]

    return [{"name": None, "windows": windows}]


async def fetch_antigravity_quota(account: dict[str, Any]) -> list[dict[str, Any]]:
    summary: dict[str, Any] = await call_provider(
        account,
        "POST",
        "https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary",
        {"Content-Type": "application/json", "User-Agent": "antigravity"},  # any other user agent gets 403
        json.dumps({"project": account["project_id"]}),
    )

    # gemini and the third-party models are separate pools
    return [
        {
            "name": group["displayName"],
            "windows": [
                {"label": bucket["bucketId"].rsplit("-", 1)[-1].replace("weekly", "7d"), "remaining": bucket["remainingFraction"] * 100, "resets_at": parse_time(bucket.get("resetTime"))}
                for bucket in reversed(group["buckets"])  # listed longest first
                if "remainingFraction" in bucket
            ],
        }
        for group in summary["groups"]
    ]


# rate limit headers of an account's last answer, kept by cliproxyapi
OBSERVERS: dict[str, Callable[[dict[str, Any]], list[dict[str, Any]]]] = {
    "claude": read_claude_quota,
    "codex": read_codex_quota,
}

# asked only while nothing current is observed; antigravity answers carry no limits
FETCHERS: dict[str, Callable[[dict[str, Any]], Coroutine[Any, Any, list[dict[str, Any]]]]] = {
    "claude": fetch_claude_quota,
    "codex": fetch_codex_quota,
    "antigravity": fetch_antigravity_quota,
}


def is_reset(snapshot: dict[str, Any], now: float) -> bool:
    resets: list[float | None] = [window["resets_at"] for pool in snapshot["pools"] for window in pool["windows"]]

    return any(reset_at is not None and reset_at < now for reset_at in resets)


def is_outdated(account: dict[str, Any], now: float) -> bool:
    snapshot: dict[str, Any] | None = snapshots.get(account["auth_index"])
    if snapshot is None:
        return True

    aged: bool = now - snapshot["fetched_at"] > QUOTA_MAX_AGE

    return snapshot["observed"] or aged or is_reset(snapshot, now)  # observed headers that went old leave it to a fetch


def observe_quota(account: dict[str, Any], now: float) -> bool:
    quota: dict[str, Any] = account["quota"]
    if not quota["signals"]:
        return False

    # other hosts spend the account unseen; headers of an old answer miss that
    observed_at: float = datetime.datetime.fromisoformat(quota["observed_at"]).timestamp()
    if now - observed_at > QUOTA_MAX_AGE:
        return False

    signals: dict[str, str] = {name.lower(): value for name, value in quota["signals"].items()}

    windows: list[dict[str, Any]] = OBSERVERS[account["provider"]]({**quota, "signals": signals})
    snapshot: dict[str, Any] = {"pools": [{"name": None, "windows": windows}], "fetched_at": observed_at, "observed": True}

    # a 429 carries no limits, a reset window says nothing current
    if not windows or is_reset(snapshot, now):
        return False

    snapshots[account["auth_index"]] = snapshot

    return True


async def refresh_quota(account: dict[str, Any], started_at: float) -> None:
    try:
        pools: list[dict[str, Any]] = await FETCHERS[account["provider"]](account)
    except (aiohttp.ClientError, OSError, RuntimeError, LookupError, TypeError, ValueError) as error:
        # the repr of a response error carries the management key; the last known quota stays and gets marked stale
        print(f"{account['provider']} quota: {type(error).__name__}: {error}", file=sys.stderr)
        return

    snapshots[account["auth_index"]] = {"pools": pools, "fetched_at": started_at, "observed": False}


async def read_quotas(timeout: float) -> dict[str, list[dict[str, Any]]]:
    files: list[dict[str, Any]] = (await call_management("GET", "/auth-files"))["files"]
    accounts: list[dict[str, Any]] = [account for account in files if not account["disabled"]]

    now: float = time.time()

    for account in accounts:
        index: str = account["auth_index"]

        observed: bool = account["provider"] in OBSERVERS and observe_quota(account, now)

        # a provider without a fetcher shows its accounts alone
        if not observed and account["provider"] in FETCHERS and is_outdated(account, now) and now - attempted_at.get(index, 0) > QUOTA_MIN_AGE:
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


def split_model(model_id: str) -> tuple[str, str]:
    name: str = model_id.removeprefix(CLOAK_PREFIX)[::-1] if model_id.startswith(CLOAK_PREFIX) else model_id

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
    # an email gives way by its name and host, the zone stays; any other label as a whole
    user, at, domain = label.partition("@")
    host, dot, zone = domain.rpartition(".")

    users: set[str] = {other.partition("@")[0] for other in labels}
    hosts: set[str] = {other.partition("@")[2].rpartition(".")[0] for other in labels}

    minimums: list[int] = [measure_part(user, users), measure_part(host, hosts)]
    lengths: list[int] = [len(user), len(host)]

    name: str = label

    # the part with more to spare gives way first, never below what tells the accounts apart
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
        client.get(f"{read_upstream()}/v1/models", headers=headers) as answer,
    ):
        catalog: dict[str, Any] = await answer.json()

    return catalog["data"]


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
        return None  # an outside file; the picker keeps cliproxyapi's order without it

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


def label_model(model: dict[str, Any]) -> str:
    provider, _ = split_model(model["id"])

    return model["display_name"] if provider == "claude" else f"{provider.capitalize()} · {model['display_name']}"


async def relay(request: web.Request) -> web.StreamResponse:
    body: bytes = await request.read()
    headers: list[tuple[str, str]] = [(name, value) for name, value in request.headers.items() if name.lower() not in FRAMING_HEADERS]

    # claude hanging up cancels the handler, which closes the upstream connection
    async with (
        aiohttp.ClientSession(auto_decompress=False, timeout=aiohttp.ClientTimeout(total=None)) as client,
        client.request(request.method, f"{read_upstream()}{request.raw_path}", headers=headers, data=body) as answer,
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

    provider, model = split_model(request.query["model"])

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

    models, quotas, lineup = await asyncio.gather(read_catalog(), read_quotas(PICKER_QUOTA_TIMEOUT), read_claude_lineup())

    catalog: list[dict[str, Any]] = order_models(models, lineup)

    account_labels: set[str] = collect_labels(quotas)

    labels: list[str] = [label_model(model) for model in catalog]

    # a row is the indent, pointer, index, the longest label and the gaps between them
    width: int = int(request.query["width"]) - max(map(len, labels)) - len(f"{len(catalog) + 1}.") - 12

    options: list[dict[str, str]] = []
    for model, label in zip(catalog, labels, strict=True):
        provider, name = split_model(model["id"])

        option: dict[str, str] = {"model": model["id"], "label": label, "description": describe_quota(name, quotas.get(provider, []), account_labels, width)}

        # under its own id a foreign model gets its own effort in `modelSettings`, not the one of the disguise
        if provider != "claude":
            option.update(model=f"{provider}/{name}", behavesAs=BEHAVES_AS)

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

    web.run_app(application, host="127.0.0.1", port=PORT, handler_cancellation=True)


if __name__ == "__main__":
    main()
