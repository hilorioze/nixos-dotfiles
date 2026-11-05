import base64
import json
import sys
import urllib.parse
import urllib.request
from xml.etree import ElementTree

SOURCES_PATH: str = "packages/chromium-extensions/sources.json"  # nix-update runs update scripts from the repository root

UPDATE_URL: str = "https://clients2.google.com/service/update2/crx"
UPDATE_NAMESPACE: str = "{http://www.google.com/update2/response}"


def fetch_update(extension_id: str, chromium_version: str) -> ElementTree.Element:
    query: str = urllib.parse.urlencode({"response": "updatecheck", "prodversion": chromium_version, "acceptformat": "crx3", "x": f"id={extension_id}&uc"})

    with urllib.request.urlopen(f"{UPDATE_URL}?{query}") as response:
        document: ElementTree.Element = ElementTree.fromstring(response.read())

    return next(document.iter(f"{UPDATE_NAMESPACE}updatecheck"))


def convert_hash(hex_digest: str) -> str:
    return "sha256-" + base64.b64encode(bytes.fromhex(hex_digest)).decode()


def main() -> None:
    name: str = sys.argv[1]
    chromium_version: str = sys.argv[2]

    with open(SOURCES_PATH) as file:
        sources: dict[str, dict[str, str]] = json.load(file)

    update: ElementTree.Element = fetch_update(sources[name]["id"], chromium_version)

    sources[name] |= {"version": update.attrib["version"], "url": update.attrib["codebase"], "hash": convert_hash(update.attrib["hash_sha256"])}

    with open(SOURCES_PATH, "w") as file:
        json.dump(sources, file, indent=2)
        file.write("\n")


if __name__ == "__main__":
    main()
