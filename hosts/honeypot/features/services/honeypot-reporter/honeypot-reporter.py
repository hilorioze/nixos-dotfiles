import json
import os
import subprocess
import time
import urllib.error
import urllib.request
from collections import Counter
from collections.abc import Callable, Iterator
from dataclasses import dataclass, field
from functools import partial
from hashlib import sha256
from html import escape
from pathlib import Path
from typing import Any

DIGEST_INTERVAL: float = 6 * 60 * 60

DIGEST_SECTIONS: tuple[str, ...] = ("connections", "ips", "credentials", "http paths", "redis commands", "tunnels", "repeated scripts")

TOP_SIZE: int = 10
KEY_LIMIT: int = 100

COMMANDS_LIMIT: int = 3000  # telegram caps a message at 4096 characters

# https://github.com/thinkst/opencanary/blob/fb12e4fefbdb1b9acd1e5561a2614f827ab639ff/opencanary/logger.py#L64-L100
OPENCANARY_SERVICES: dict[int, str] = {
    2000: "ftp",
    3000: "http",
    3001: "http login",
    7001: "http proxy",
    8001: "mysql",
    9001: "mssql",
    9002: "mssql",
    10001: "tftp",
    11001: "ntp",
    12001: "vnc",
    13001: "snmp",
    14001: "rdp",
    15001: "sip",
    16001: "git",
    17001: "redis",
    20001: "mongodb",
}


@dataclass(slots=True, kw_only=True)
class Session:
    protocol: str
    src_ip: str
    client_version: str = ""
    login: str = ""
    commands: list[str] = field(default_factory=list)
    files: list[tuple[str, str]] = field(default_factory=list)
    tunnels: Counter[str] = field(default_factory=Counter)


def send_message(text: str, *, bot_token: str, chat_id: str) -> None:
    payload: dict[str, Any] = {
        "chat_id": chat_id,
        "text": text,
        "parse_mode": "HTML",
        "disable_notification": True,
        "link_preview_options": {"is_disabled": True},
    }

    request: urllib.request.Request = urllib.request.Request(
        f"https://api.telegram.org/bot{bot_token}/sendMessage",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )

    try:
        urllib.request.urlopen(request).close()
    except urllib.error.HTTPError as error:
        if error.code != 429:
            raise

        time.sleep(json.load(error)["parameters"]["retry_after"])

        send_message(text, bot_token=bot_token, chat_id=chat_id)


def follow_logs(paths: list[str]) -> Iterator[dict[str, Any]]:
    # `--follow=name` survives the files appearing after the start
    with subprocess.Popen(["tail", "--follow=name", "--retry", "--lines=0", "--quiet", *paths], stdout=subprocess.PIPE, text=True) as tail:
        assert tail.stdout is not None  # `stdout=PIPE` always opens it

        for line in tail.stdout:
            yield json.loads(line)


def create_digest() -> dict[str, Counter[str]]:
    return {section: Counter() for section in DIGEST_SECTIONS}


def format_counter(counter: Counter[str]) -> str:
    return "\n".join(f"{count} <code>{escape(key[:KEY_LIMIT])}</code>" for key, count in counter.most_common(TOP_SIZE))


def format_digest(digest: dict[str, Counter[str]]) -> str:
    hours: int = int(DIGEST_INTERVAL // 3600)

    lines: list[str] = [f"<b>{len(digest['ips'])} ips in {hours}h</b>"]

    for section, counter in digest.items():
        if counter:
            lines.append(f"\n<b>{section}</b>\n{format_counter(counter)}")

    return "\n".join(lines)


def format_session(session: Session, *, script: str) -> str:
    lines: list[str] = [f"<b>{session.protocol}</b> <code>{session.src_ip}</code> {escape(session.client_version)}"]

    if session.login:
        lines.append(f"login <code>{escape(session.login)}</code>")

    if session.commands:
        commands: str = "\n".join(session.commands)[:COMMANDS_LIMIT]

        lines.append(f"<pre>{escape(commands)}</pre>")

    lines.extend(f'file <a href="https://www.virustotal.com/gui/file/{shasum}">{escape(source[:KEY_LIMIT])}</a>' for source, shasum in session.files)

    if session.tunnels:
        lines.append(f"tunnels\n{format_counter(session.tunnels)}")

    lines.append(f"script <code>{script}</code>")

    return "\n".join(lines)


def report_session(session: Session, *, known_scripts: set[str], digest: dict[str, Counter[str]], send: Callable[[str], None]) -> None:
    if not (session.commands or session.files or session.tunnels):
        return

    script: str = sha256("\n".join(session.commands).encode()).hexdigest()[:8]

    # bots repeat the same script from thousands of hosts
    if script in known_scripts:
        digest["repeated scripts"][script] += 1

        return

    known_scripts.add(script)

    send(format_session(session, script=script))


def handle_cowrie_event(event: dict[str, Any], *, sessions: dict[str, Session], known_scripts: set[str], digest: dict[str, Counter[str]], send: Callable[[str], None]) -> None:
    if event["eventid"] == "cowrie.session.connect":
        sessions[event["session"]] = Session(protocol=event["protocol"], src_ip=event["src_ip"])

        digest["connections"][event["protocol"]] += 1
        digest["ips"][event["src_ip"]] += 1

        return

    # sessions opened before the reporter started have no connect event
    session: Session | None = sessions.get(event["session"])

    if session is None:
        return

    match event["eventid"]:
        case "cowrie.client.version":
            session.client_version = event["version"]
        case "cowrie.login.failed":
            digest["credentials"][f"{event['username']}:{event['password']}"] += 1
        case "cowrie.login.success":
            session.login = f"{event['username']}:{event['password']}"

            digest["credentials"][session.login] += 1
        case "cowrie.command.input":
            session.commands.append(event["input"])
        case "cowrie.session.file_download":
            session.files.append((event["url"], event["shasum"]))
        case "cowrie.session.file_upload":
            session.files.append((event["filename"], event["shasum"]))
        case "cowrie.direct-tcpip.request":
            tunnel: str = f"{event['dst_ip']}:{event['dst_port']}"

            session.tunnels[tunnel] += 1
            digest["tunnels"][tunnel] += 1
        case "cowrie.session.closed":
            del sessions[event["session"]]

            report_session(session, known_scripts=known_scripts, digest=digest, send=send)


def handle_opencanary_event(event: dict[str, Any], *, digest: dict[str, Counter[str]]) -> None:
    service: str | None = OPENCANARY_SERVICES.get(event["logtype"])

    # opencanary's own messages
    if service is None:
        return

    logdata: dict[str, Any] = event["logdata"]

    digest["connections"][service] += 1
    digest["ips"][event["src_host"]] += 1

    if "USERNAME" in logdata:
        digest["credentials"][f"{logdata['USERNAME']}:{logdata.get('PASSWORD', '')}"] += 1

    if "PATH" in logdata:
        digest["http paths"][logdata["PATH"]] += 1

    if "CMD" in logdata:
        digest["redis commands"][f"{logdata['CMD']} {logdata['ARGS']}"] += 1


def main() -> None:
    bot_token: str = (Path(os.environ["CREDENTIALS_DIRECTORY"]) / "telegram-bot-token").read_text().strip()

    send: Callable[[str], None] = partial(send_message, bot_token=bot_token, chat_id=os.environ["TELEGRAM_CHAT_ID"])

    sessions: dict[str, Session] = {}
    known_scripts: set[str] = set()

    digest: dict[str, Counter[str]] = create_digest()
    digest_started_at: float = time.monotonic()

    for event in follow_logs([os.environ["COWRIE_LOG"], os.environ["OPENCANARY_LOG"]]):
        if "eventid" in event:
            handle_cowrie_event(event, sessions=sessions, known_scripts=known_scripts, digest=digest, send=send)
        else:
            handle_opencanary_event(event, digest=digest)

        # the honeypots never stay quiet for long, so the next event is a good enough clock
        if time.monotonic() - digest_started_at >= DIGEST_INTERVAL:
            send(format_digest(digest))

            digest = create_digest()
            digest_started_at = time.monotonic()


if __name__ == "__main__":
    main()
