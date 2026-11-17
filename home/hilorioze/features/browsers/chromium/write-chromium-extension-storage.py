import json
import sys

import plyvel


def main() -> None:
    storage_path: str = sys.argv[1]
    values_path: str = sys.argv[2]

    with open(values_path) as file:
        values: dict[str, object] = json.load(file)

    # a running chromium holds the storage lock; the values are written on the next sops-nix run with chromium closed
    try:
        database: plyvel.DB = plyvel.DB(storage_path, create_if_missing=True)
    except plyvel.IOError:
        print("chromium is running, skipping the keepassxc-browser storage", file=sys.stderr)
        return

    with database.write_batch() as batch:
        for key, value in values.items():
            batch.put(key.encode(), json.dumps(value, separators=(",", ":")).encode())

    database.close()


if __name__ == "__main__":
    main()
