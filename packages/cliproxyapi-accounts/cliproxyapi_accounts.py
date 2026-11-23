import datetime
import json
import os
import sys
from collections.abc import Callable, Coroutine
from pathlib import Path
from typing import Any

import aiohttp

CLIPROXYAPI_URL: str = os.environ["CLIPROXYAPI_URL"]

CODEX_HEADERS: dict[str, str] = json.loads(Path(os.environ["CLIPROXYAPI_CODEX_HEADERS"]).read_text())

CLIPROXYAPI_TIMEOUT: aiohttp.ClientTimeout = aiohttp.ClientTimeout(total=10)

ACCOUNT_ERRORS: tuple[type[Exception], ...] = (aiohttp.ClientError, OSError, RuntimeError, LookupError, TypeError, ValueError)  # one failing account must not stop the others

WINDOW_LENGTHS: dict[str, int] = {"5h": 18000, "7d": 604800}


def read_key(name: str) -> str:
    with open(os.path.join(os.environ["CREDENTIALS_DIRECTORY"], name)) as file:
        return file.read()


def print_account_error(account: dict[str, Any], *, error: Exception) -> None:
    # the repr of a response error carries the management key
    print(f"{account['provider']} {account['label']}: {type(error).__name__}: {error}", file=sys.stderr)


async def call_management(*, method: str, path: str, payload: dict[str, Any] | None = None) -> Any:
    headers: dict[str, str] = {"Authorization": f"Bearer {read_key('management-key')}"}

    async with (
        aiohttp.ClientSession(timeout=CLIPROXYAPI_TIMEOUT, raise_for_status=True) as client,
        client.request(method, f"{CLIPROXYAPI_URL}/v0/management{path}", json=payload, headers=headers) as answer,
    ):
        return await answer.json()


async def send_provider_request(account: dict[str, Any], *, method: str, url: str, headers: dict[str, str], data: str = "") -> dict[str, Any]:
    # cliproxyapi sends the request itself and puts the account's oauth token in place of `$TOKEN$`
    response: dict[str, Any] = await call_management(
        method="POST",
        path="/api-call",
        payload={
            "auth_index": account["auth_index"],
            "method": method,
            "url": url,
            "header": {"Authorization": "Bearer $TOKEN$", **headers},
            "data": data,
        },
    )

    if response["status_code"] != 200:
        raise RuntimeError(f"{url} answered {response['status_code']}: {' '.join(response['body'].split())}")  # the provider's error message, on one journal line

    return response


async def call_provider(account: dict[str, Any], *, method: str, url: str, headers: dict[str, str], data: str = "") -> Any:
    response: dict[str, Any] = await send_provider_request(account, method=method, url=url, headers=headers, data=data)

    return json.loads(response["body"])


def parse_time(value: str | None) -> float | None:
    if value is None:
        return None

    return datetime.datetime.fromisoformat(value).timestamp()


def format_window_length(seconds: int) -> str:
    if seconds % 86400 == 0:
        return f"{seconds // 86400}d"

    return f"{seconds // 3600}h"


async def fetch_claude_usage(account: dict[str, Any]) -> dict[str, Any]:
    return await call_provider(account, method="GET", url="https://api.anthropic.com/api/oauth/usage", headers={"anthropic-beta": "oauth-2025-04-20"})


async def fetch_claude_quota(account: dict[str, Any]) -> list[dict[str, Any]]:
    usage: dict[str, Any] = await fetch_claude_usage(account)

    windows: list[dict[str, Any]] = []

    for key, label in (("five_hour", "5h"), ("seven_day", "7d")):
        window: dict[str, Any] = usage[key]

        windows.append({"label": label, "length": WINDOW_LENGTHS[label], "remaining": 100 - window["utilization"], "resets_at": parse_time(window["resets_at"])})  # no reset until the window starts

    return [{"name": None, "windows": windows}]


async def fetch_codex_usage(account: dict[str, Any]) -> dict[str, Any]:
    return await call_provider(account, method="GET", url="https://chatgpt.com/backend-api/wham/usage", headers={**CODEX_HEADERS, "ChatGPT-Account-Id": account["id_token"]["chatgpt_account_id"]})


async def fetch_codex_quota(account: dict[str, Any]) -> list[dict[str, Any]]:
    usage: dict[str, Any] = await fetch_codex_usage(account)

    windows: list[dict[str, Any]] = [
        {
            "label": format_window_length(window["limit_window_seconds"]),
            "length": window["limit_window_seconds"],
            "remaining": 100 - window["used_percent"],
            "resets_at": None if window["reset_after_seconds"] == window["limit_window_seconds"] else window["reset_at"],  # an unstarted window counts its whole length from now
        }
        for window in (usage["rate_limit"].get("primary_window"), usage["rate_limit"].get("secondary_window"))
        if window
    ]

    return [{"name": None, "windows": windows}]


FETCHERS: dict[str, Callable[[dict[str, Any]], Coroutine[Any, Any, list[dict[str, Any]]]]] = {
    "claude": fetch_claude_quota,
    "codex": fetch_codex_quota,
}
