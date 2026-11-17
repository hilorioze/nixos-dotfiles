import argparse
import shlex
import subprocess
import time
from pathlib import Path

DRM_PATH: Path = Path("/sys/class/drm")

POLL_INTERVAL: float = 1
DISPLAYS_OFF_DELAY: float = 5


def parse_arguments() -> argparse.Namespace:
    parser: argparse.ArgumentParser = argparse.ArgumentParser()
    parser.add_argument("--displays-on-command", type=shlex.split, required=True)
    parser.add_argument("--displays-off-command", type=shlex.split, required=True)

    arguments: argparse.Namespace = parser.parse_args()

    return arguments


def is_connector_on(connector: Path) -> bool:
    status: str = (connector / "status").read_text().strip()
    dpms: str = (connector / "dpms").read_text().strip()

    return status == "connected" and dpms == "On"


def are_displays_on() -> bool:
    return any(is_connector_on(connector) for connector in DRM_PATH.glob("card*-*"))


def watch_displays(*, displays_on_command: list[str], displays_off_command: list[str]) -> None:
    reported_displays_on: bool | None = None
    displays_off_since: float | None = None

    while True:
        displays_on: bool = are_displays_on()

        if displays_on:
            displays_off_since = None
        elif displays_off_since is None:
            displays_off_since = time.monotonic()

        # outputs go off for a moment while one compositor hands them over to the next, e.g. on login
        settled: bool = displays_off_since is None or time.monotonic() - displays_off_since >= DISPLAYS_OFF_DELAY

        if settled and displays_on != reported_displays_on:
            subprocess.run(displays_on_command if displays_on else displays_off_command, check=False)

            reported_displays_on = displays_on

        time.sleep(POLL_INTERVAL)


def main() -> None:
    arguments: argparse.Namespace = parse_arguments()

    watch_displays(displays_on_command=arguments.displays_on_command, displays_off_command=arguments.displays_off_command)


if __name__ == "__main__":
    main()
