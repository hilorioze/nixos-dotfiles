import argparse
import time
from pathlib import Path

DRIVER_PATH: Path = Path("/sys/bus/hid/drivers/razerkbd")

MATRIX_ROWS: int = 6
MATRIX_COLUMNS: int = 22


def parse_arguments() -> argparse.Namespace:
    parser: argparse.ArgumentParser = argparse.ArgumentParser()
    subparsers: argparse._SubParsersAction = parser.add_subparsers(dest="command", required=True)

    store_parser: argparse.ArgumentParser = subparsers.add_parser("store")
    store_parser.add_argument("--color", type=bytes.fromhex, required=True)
    store_parser.add_argument("--brightness", type=int, required=True)

    show_parser: argparse.ArgumentParser = subparsers.add_parser("show")
    show_parser.add_argument("--color", type=bytes.fromhex, required=True)
    show_parser.add_argument("--repeat-interval", type=float)

    arguments: argparse.Namespace = parser.parse_args()

    return arguments


def find_device() -> Path:
    # of the keyboard's interfaces only the lighting one has the `matrix_*` attributes
    return next(DRIVER_PATH.glob("*/matrix_brightness")).parent


def store_backlight(device: Path, *, color: bytes, brightness: int) -> None:
    (device / "matrix_effect_static").write_bytes(color)
    (device / "matrix_brightness").write_text(str(brightness))


def build_frame(color: bytes) -> bytes:
    row: bytes = color * MATRIX_COLUMNS

    return b"".join(bytes([row_index, 0, MATRIX_COLUMNS - 1]) + row for row_index in range(MATRIX_ROWS))


def show_frame(device: Path, *, frame: bytes) -> None:
    (device / "matrix_custom_frame").write_bytes(frame)
    (device / "matrix_effect_custom").write_bytes(b"1")


def main() -> None:
    arguments: argparse.Namespace = parse_arguments()

    device: Path = find_device()

    if arguments.command == "store":
        store_backlight(device, color=arguments.color, brightness=arguments.brightness)

        return

    frame: bytes = build_frame(arguments.color)

    show_frame(device, frame=frame)

    # after a resume the keyboard stays dark for a while whatever it gets, and nothing tells when it shows frames again
    while arguments.repeat_interval is not None:
        time.sleep(arguments.repeat_interval)

        show_frame(device, frame=frame)


if __name__ == "__main__":
    main()
