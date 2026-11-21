import asyncio
import sys
from typing import Any

from cliproxyapi_accounts import ACCOUNT_ERRORS, call_management, call_provider

POLL_INTERVAL: float = 60  # cliproxyapi starts from the nix config, which has no models


def read_efforts(model: dict[str, Any]) -> list[str]:
    # openrouter lists them under `reasoning`, kilo in the options of its opencode client
    if efforts := (model.get("reasoning") or {}).get("supported_efforts"):
        return efforts

    options: list[dict[str, Any]] = (model.get("opencode") or {}).get("reasoning_options") or []

    return next((option["values"] for option in options if option["type"] == "effort"), [])


def build_model(model: dict[str, Any]) -> dict[str, Any]:
    entry: dict[str, Any] = {"name": model["id"], "alias": model["id"]}

    if name := model.get("name"):
        entry["display-name"] = name

    # nvidia calls it `context_window`
    if context_length := model.get("context_length") or model.get("context_window"):
        entry["max-context-length"] = context_length

    architecture: dict[str, Any] = model.get("architecture") or {}
    if input_modalities := architecture.get("input_modalities"):
        entry["input-modalities"] = input_modalities

    if output_modalities := architecture.get("output_modalities"):
        entry["output-modalities"] = output_modalities

    # without levels cliproxyapi offers `low`, `medium` and `high` and clamps the rest to them
    if efforts := read_efforts(model):
        entry["thinking"] = {"levels": efforts}

    return entry


async def fetch_models(provider: dict[str, Any]) -> list[dict[str, Any]]:
    key: dict[str, Any] = provider["api-key-entries"][0]
    catalog: dict[str, Any] = await call_provider({"auth_index": key["auth-index"]}, method="GET", url=f"{provider['base-url']}/models", headers={})

    return [build_model(model) for model in catalog["data"]]


async def sync_models() -> None:
    listing: dict[str, Any] = await call_management(method="GET", path="/openai-compatibility")

    for provider in listing["openai-compatibility"]:
        try:
            models: list[dict[str, Any]] = await fetch_models(provider)
            if models == provider.get("models"):  # the listing leaves out an empty list
                continue

            # cliproxyapi saves the config and reloads the provider's models
            await call_management(method="PATCH", path="/openai-compatibility", payload={"name": provider["name"], "value": {"models": models}})
            print(f"{provider['name']}: {len(models)} models", file=sys.stderr)
        except ACCOUNT_ERRORS as error:
            print(f"{provider['name']}: {type(error).__name__}: {error}", file=sys.stderr)


async def run() -> None:
    while True:
        try:
            await sync_models()
        except ACCOUNT_ERRORS as error:
            print(f"poll failed: {error}", file=sys.stderr)

        await asyncio.sleep(POLL_INTERVAL)


def main() -> None:
    asyncio.run(run())


if __name__ == "__main__":
    main()
