import shlex
import shutil
import sys
from pathlib import Path


def read_command(entry: Path) -> str | None:
    group: str = ""

    for line in entry.read_text().splitlines():
        if line.startswith("["):
            group = line
        elif group == "[Desktop Entry]" and line.startswith("Exec="):
            return line.removeprefix("Exec=")

    return None


def find_program(command: str) -> str:
    arguments: list[str] = shlex.split(command)

    if arguments[0] != "env":
        return arguments[0]

    # `env` runs the first argument after the variable assignments
    return next(argument for argument in arguments[1:] if "=" not in argument)


def main() -> None:
    applications_dir: Path = Path(sys.argv[1])

    for entry in applications_dir.rglob("*.desktop"):
        command: str | None = read_command(entry)

        if command is not None and shutil.which(find_program(command)) is None:
            print(f"removing {entry}")
            entry.unlink()


if __name__ == "__main__":
    main()
