import os
import shutil
import sys
import tempfile

import plyvel

EXTENSION_ID: str = "mmlmfjhmonkocbjadbfplnigmagldckm"


def read_token(storage: str) -> str | None:
    with tempfile.TemporaryDirectory() as directory:
        copy: str = os.path.join(directory, "leveldb")

        shutil.copytree(storage, copy, ignore=shutil.ignore_patterns("LOCK"))

        database: plyvel.DB = plyvel.DB(copy)
        try:
            value: bytes | None = database.get(f"_chrome-extension://{EXTENSION_ID}".encode() + b"\x00\x01auth-token")
        finally:
            database.close()

    # the first byte marks the encoding; the token is base64url, so it is always stored as latin-1 (1)
    if value is None or not value.startswith(b"\x01"):
        return None

    return value[1:].decode("latin-1")


def main() -> None:
    storage: str = os.path.join(sys.argv[1], "Default", "Local Storage", "leveldb")

    try:
        token: str | None = read_token(storage)
    except (OSError, plyvel.Error):
        return

    if token:
        print(token)


if __name__ == "__main__":
    main()
