import asyncio
import sys
from collections.abc import Callable, Coroutine
from typing import Any

from cliproxyapi_accounts import (
    ACCOUNT_ERRORS,
    call_management,
    fetch_claude_usage,
    fetch_codex_usage,
    print_account_error,
)

POLL_INTERVAL: float = 60


def has_quota_cooldown(account: dict[str, Any]) -> bool:
    cooldowns: list[dict[str, Any]] = account["cooldowns"] or []

    # shared usage does not establish recovery from model-level rate limits
    return any(cooldown["scope"] == "credential" and cooldown["reason"] == "credential_quota" and cooldown["remaining_seconds"] > 0 for cooldown in cooldowns)


async def check_claude_quota(account: dict[str, Any]) -> bool:
    usage: dict[str, Any] = await fetch_claude_usage(account)
    windows: list[dict[str, Any]] = [window for key, window in usage.items() if (key.startswith(("five_hour", "seven_day")) or key == "iguana_necktie") and window is not None]
    limits: list[dict[str, Any]] = usage.get("limits") or []

    return bool(windows) and all(window["utilization"] is not None and window["utilization"] < 100 for window in windows) and all(limit["percent"] is not None and limit["percent"] < 100 for limit in limits if limit["is_active"])


def check_codex_limit(limit: dict[str, Any]) -> bool:
    windows: list[dict[str, Any]] = [window for key in ("primary_window", "secondary_window") if (window := limit.get(key)) is not None]

    return limit["allowed"] and not limit["limit_reached"] and all(window["used_percent"] < 100 for window in windows)


async def check_codex_quota(account: dict[str, Any]) -> bool:
    usage: dict[str, Any] = await fetch_codex_usage(account)
    shared: dict[str, Any] | None = usage["rate_limit"]
    if not shared:
        return False

    limits: list[dict[str, Any]] = [shared]
    if code_review := usage.get("code_review_rate_limit"):
        limits.append(code_review)

    for additional in usage.get("additional_rate_limits") or []:
        if limit := additional.get("rate_limit"):
            limits.append(limit)

    return all(check_codex_limit(limit) for limit in limits)


CHECKERS: dict[str, Callable[[dict[str, Any]], Coroutine[Any, Any, bool]]] = {
    "claude": check_claude_quota,
    "codex": check_codex_quota,
}


async def clear_stale_cooldowns() -> None:
    listing: dict[str, Any] = await call_management("GET", "/auth-files")

    for account in listing["files"]:
        if account["disabled"] or not has_quota_cooldown(account):
            continue

        checker: Callable[[dict[str, Any]], Coroutine[Any, Any, bool]] | None = CHECKERS.get(account["provider"])
        if checker is None:
            continue

        try:
            if not await checker(account):
                continue

            # the management reset clears every model cooldown of the selected account
            result: dict[str, Any] = await call_management("POST", "/reset-quota", {"auth_index": account["auth_index"]})
            models: str = ", ".join(result["models"])
            print(f"{account['provider']} {account['label']}: reset cooldowns ({models})", file=sys.stderr)
        except ACCOUNT_ERRORS as error:
            print_account_error(account, error)


async def run() -> None:
    while True:
        try:
            await clear_stale_cooldowns()
        except ACCOUNT_ERRORS as error:
            print(f"poll failed: {error}", file=sys.stderr)

        await asyncio.sleep(POLL_INTERVAL)


def main() -> None:
    asyncio.run(run())


if __name__ == "__main__":
    main()
