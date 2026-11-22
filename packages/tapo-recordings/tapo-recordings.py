import asyncio
import base64
import hashlib
import hmac
import json
import os
import shutil
import socket
import ssl
import struct
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
import urllib.request
import uuid
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any

from firebase_messaging import FcmPushClient, FcmRegisterConfig
from firebase_messaging.proto.mcs_pb2 import DataMessageStanza
from pytapo import Tapo
from pytapo.media_stream.downloader import Downloader

CLOUD_URL: str = "https://n-euw1-wap.i.tplinkcloud.com"
CLOUD_CONTEXT: ssl.SSLContext = ssl.create_default_context(cafile="@cloudCa@")  # the cloud's certificates chain to tp-link's own ca, shipped in the app

# public constants of the tapo android app
ACCESS_KEY: str = "4d11b6b9d5ea4d19a829adbb9714b057"
SIGNING_KEY: bytes = b"6ed7d97f3e73467f8a5bab90b577ba4c"
SIGNED_TIMESTAMP: str = "9999999999"  # the app signs every request with this fixed timestamp
PUSH_CONFIG: FcmRegisterConfig = FcmRegisterConfig(project_id="tapo-android", app_id="1:53827594216:android:e95bca87d0bc49bc", api_key="", messaging_sender_id="53827594216")

# the app on the phone, which the daemon passes for
CLIENT_QUERY: dict[str, str] = {
    "appName": "TP-Link_Tapo_Android",
    "appVer": "3.22.105",
    "netType": "wifi",
    "ospf": "Android 16",
    "brand": "TPLINK",
    "locale": "en_IE",
    "model": "Pixel 7a",
    "termName": "Google Pixel 7a",
    "termMeta": "1",
}
APP_VERSION_CODE: int = 7205  # the build number of `appVer`

DETECTION_TYPES: list[str] = ["Motion", "PersonDetected", "PersonEnhanced"]

HISTORY_MS: int = 12 * 3600 * 1000  # a longer window drops recent events from the reply
OVERLAP_MS: int = 3600 * 1000  # re-read the last hour so events stored out of order aren't missed
HISTORY_SECONDS: int = 60

EXPIRED_TOKEN_ERROR: int = -20651  # a token lasts about 30 days

UNREGISTERED_TOKEN_ERROR: int = -23001  # `APP_NO_SUCH_APP` in the app; the cloud keeps one push registration per account, and the app on a phone takes it on start at most once a day
REGISTRATION_SECONDS: int = 10  # how long a phone can keep the pushes after taking the registration

IDLE_SECONDS: int = 120  # keep waiting for the recording of the latest detection
RESUME_MS: int = 3600 * 1000  # on start, resume saving the recordings of the cameras with a detection this recent
POLL_SECONDS: int = 5

# surveillance station's own sizes: a 160x90 thumbnail of the recording and a 320x180 preview every 20s for the timeline
THUMBNAIL_SCALE: str = "160:90"
PREVIEW_SCALE: str = "320:180"
PREVIEW_SECONDS: int = 20

CREDENTIALS_PATH: Path = Path(os.environ["CREDENTIALS_DIRECTORY"])
TERMINAL_UUID: str = (CREDENTIALS_PATH / "terminal-uuid").read_text()
ANDROID_ID: str = (CREDENTIALS_PATH / "android-id").read_text()
SECURITY_TOKEN: str = (CREDENTIALS_PATH / "security-token").read_text()
REGISTRATION_TOKEN: str = (CREDENTIALS_PATH / "registration-token").read_text()
USERNAME: str = (CREDENTIALS_PATH / "cloud-username").read_text()
PASSWORD: str = (CREDENTIALS_PATH / "cloud-password").read_text()

IMPORT_PATH: Path = Path(sys.argv[1])  # a folder per camera named by its mac address, holding its alias and its recordings for surveillance station

STATE_PATH: Path = Path(os.environ["STATE_DIRECTORY"])
DETECTIONS_PATH: Path = STATE_PATH / "detections.json"  # the time of every recent detection by its message id
LATEST_PATH: Path = STATE_PATH / "cameras.json"  # the alias and the time of the latest detection of every camera by its mac address
SAVED_PATH: Path = STATE_PATH / "saved"  # a folder per camera with a file per saved recording, named by its start time

METRICS_PATH: Path = Path(os.environ["RUNTIME_DIRECTORY"]) / "tapo-cameras.prom"  # every camera of the account, for the alerts to pick the cameras out of the router's hosts

seen: dict[str, int] = json.loads(DETECTIONS_PATH.read_text()) if DETECTIONS_PATH.exists() else {}
cameras: dict[str, str] = {}  # the mac address of every camera by its device id
token: str = ""  # the cloud's session of this terminal

# by the camera's mac address
latest: dict[str, dict[str, Any]] = json.loads(LATEST_PATH.read_text()) if LATEST_PATH.exists() else {}  # its alias and the time of its latest detection
last_detected_at: dict[str, float] = {}  # when a new detection or a restart last asked its saving thread to keep going
savers: dict[str, threading.Thread] = {}  # the thread saving its recordings


def post_cloud(*, path: str, parameters: dict[str, Any], query: dict[str, str]) -> dict[str, Any]:
    body: bytes = json.dumps(parameters, separators=(",", ":")).encode()
    digest: str = base64.b64encode(hashlib.md5(body).digest()).decode()

    nonce: str = str(uuid.uuid4())
    signature: str = hmac.new(SIGNING_KEY, f"{digest}\n{SIGNED_TIMESTAMP}\n{nonce}\n{path}".encode(), hashlib.sha1).hexdigest()

    request: urllib.request.Request = urllib.request.Request(
        f"{CLOUD_URL}{path}?{urllib.parse.urlencode({**CLIENT_QUERY, 'termID': TERMINAL_UUID, **query})}",
        data=body,
        headers={
            "Content-Type": "application/json;charset=UTF-8",
            "Content-MD5": digest,
            "X-Authorization": f"Timestamp={SIGNED_TIMESTAMP}, Nonce={nonce}, AccessKey={ACCESS_KEY}, Signature={signature}",
        },
    )
    with urllib.request.urlopen(request, context=CLOUD_CONTEXT, timeout=30) as response:
        return json.load(response)


def log_in() -> None:
    global token

    reply: dict[str, Any] = post_cloud(
        path="/api/v2/account/login",
        parameters={
            "appType": CLIENT_QUERY["appName"],
            "appVersion": CLIENT_QUERY["appVer"],
            "cloudUserName": USERNAME,
            "cloudPassword": PASSWORD,
            "platform": CLIENT_QUERY["ospf"],
            "refreshTokenNeeded": False,
            "terminalMeta": CLIENT_QUERY["termMeta"],
            "terminalName": CLIENT_QUERY["termName"],
            "terminalUUID": TERMINAL_UUID,
        },
        query={},
    )

    # a refused login, such as one waiting for an mfa code, carries its reason in the result, next to the account's email
    result: dict[str, Any] = reply.get("result", {})
    if "token" not in result:
        sys.exit(f"login: {reply['error_code']} {result.get('errorMsg', reply.get('msg'))}")

    token = result["token"]


def request_cloud(*, method: str, parameters: dict[str, Any]) -> dict[str, Any]:
    reply: dict[str, Any] = post_cloud(path=f"/api/v2/common/{method}", parameters=parameters, query={"token": token})

    if reply["error_code"] != EXPIRED_TOKEN_ERROR:
        return reply

    log_in()

    return post_cloud(path=f"/api/v2/common/{method}", parameters=parameters, query={"token": token})


def call_cloud(*, method: str, parameters: dict[str, Any]) -> dict[str, Any]:
    reply: dict[str, Any] = request_cloud(method=method, parameters=parameters)

    # the cloud answers errors such as an expired token with http 200
    if reply["error_code"] != 0:
        sys.exit(f"{method}: {reply}")

    return reply


def fetch_cameras() -> dict[str, str]:
    devices: list[dict[str, Any]] = call_cloud(method="getDeviceList", parameters={"deviceType": "SMART.IPCAMERA"})["result"]["deviceList"]

    return {device["deviceId"]: device["deviceMac"] for device in devices}


def export_cameras() -> None:
    # the notation of the router's hosts metrics, which the alerts join on
    macs: list[str] = [":".join(mac[index : index + 2] for index in range(0, len(mac), 2)).lower() for mac in cameras.values()]

    # don't let node-exporter read a half-written file
    temporary_path: Path = METRICS_PATH.with_suffix(".tmp")
    temporary_path.write_text("".join(f'tapo_camera{{mac="{mac}"}} 1\n' for mac in macs))
    temporary_path.rename(METRICS_PATH)


def register_push() -> None:
    call_cloud(
        method="postPushInfo",
        parameters={
            "mobileType": "ANDROID",
            "versionCode": APP_VERSION_CODE,
            "appPackageName": "com.tplink.iot",
            "deviceToken": REGISTRATION_TOKEN,
            "appType": CLIENT_QUERY["appName"],
            "locale": "en_US",
            "terminalUUID": TERMINAL_UUID,
            "supportNotificationMsg": True,
        },
    )
    # every event of every camera, whatever the app's notification settings say
    call_cloud(method="subscribeMsg", parameters={"appType": CLIENT_QUERY["appName"], "deviceToken": REGISTRATION_TOKEN, "subscribeMsgType": [f"{device_id}:all" for device_id in cameras]})

    print(f"registered for the pushes of {len(cameras)} cameras", flush=True)


def hold_push_registration() -> bool:
    reply: dict[str, Any] = request_cloud(method="getSubscribeMsgType", parameters={"appType": CLIENT_QUERY["appName"], "deviceToken": REGISTRATION_TOKEN})

    if reply["error_code"] != UNREGISTERED_TOKEN_ERROR:
        return False

    register_push()

    return True


def fetch_detections(since: int) -> list[dict[str, Any]]:
    detections: list[dict[str, Any]] = []
    while True:
        page: dict[str, Any] = call_cloud(
            method="getAppNotificationByPage",
            parameters={
                "appType": CLIENT_QUERY["appName"],
                "mobileType": "ANDROID",
                "terminalUUID": TERMINAL_UUID,
                "deviceToken": "",
                "locale": "en_US",
                "direction": "asc",
                "index": len(detections),
                "indexTime": since,
                "limit": 50,
                "contentVersion": 3,
                "msgTypes": DETECTION_TYPES,
            },
        )["result"]
        detections += page["notifications"]

        if not page["hasNextPage"]:
            return detections


def read_gateway() -> str:
    routes: list[list[str]] = [route.split() for route in Path("/proc/net/route").read_text().splitlines()[1:]]  # [1:] skips header row
    gateway: str = next(route[2] for route in routes if route[1] == "00000000")

    return socket.inet_ntoa(struct.pack("<I", int(gateway, 16)))  # the kernel prints the address as a little-endian hex number


def find_camera_host(mac: str) -> str:
    # the router serves a self-signed certificate
    context: ssl.SSLContext = ssl._create_unverified_context()
    with urllib.request.urlopen(f"https://{read_gateway()}/api/v1/hosts", context=context, timeout=30) as response:
        hosts: list[dict[str, Any]] = json.load(response)[0]["hosts"]["list"]

    return next(host["ipaddress"] for host in hosts if host["macaddress"].replace(":", "").upper() == mac)


def list_recordings(tapo: Tapo, day: date) -> list[dict[str, Any]]:
    return [next(iter(entry.values())) for entry in tapo.getRecordings(f"{day:%Y%m%d}")]


def download_recording(tapo: Tapo, *, recording: dict[str, Any], clip_path: Path) -> tuple[str, float]:
    downloader: Downloader = Downloader(tapo, recording["startTime"], recording["endTime"], tapo.getTimeCorrection(), f"{clip_path.parent}/", fileName=clip_path.name)
    statuses: list[dict[str, Any] | str] = []  # the downloader reports its progress as dicts between the start and finish messages
    status: dict[str, Any] = asyncio.run(downloader.downloadFile(callbackFunc=statuses.append))

    # the progress is the length of the video the camera has sent so far
    downloaded_seconds: float = max((progress["progress"] for progress in statuses if isinstance(progress, dict)), default=0)

    return status["currentAction"], downloaded_seconds


def grab_frame(clip_path: Path, *, offset: int, scale: str) -> bytes:
    return subprocess.run(["ffmpeg", "-loglevel", "error", "-ss", str(offset), "-i", clip_path, "-frames:v", "1", "-vf", f"scale={scale}", "-f", "mjpeg", "-"], capture_output=True, check=True).stdout


def import_clip(clip_path: Path, *, recording: dict[str, Any], camera_path: Path) -> None:
    started_at: datetime = datetime.fromtimestamp(recording["startTime"])
    folder: str = f"{started_at:%Y%m%d%p}"

    # build the camera folder's layout aside, hidden from the import, then move it in with the clip last
    with tempfile.TemporaryDirectory(prefix=".", dir=camera_path) as temporary:
        layout_path: Path = Path(temporary)

        thumbnail_path: Path = layout_path / "@SSRECMETA" / "Thumbnail" / folder / str(recording["startTime"])
        thumbnail_path.parent.mkdir(parents=True)
        thumbnail_path.write_bytes(base64.b64encode(grab_frame(clip_path, offset=0, scale=THUMBNAIL_SCALE)))

        previews_path: Path = layout_path / "@SSRECMETA" / "Preview" / folder / str(recording["startTime"])
        previews_path.mkdir(parents=True)
        for preview_time in range(recording["startTime"] // PREVIEW_SECONDS * PREVIEW_SECONDS, recording["endTime"], PREVIEW_SECONDS):
            (previews_path / str(preview_time)).write_bytes(grab_frame(clip_path, offset=max(preview_time - recording["startTime"], 0), scale=PREVIEW_SCALE))

        # the layout of surveillance station's own recording names; reindex takes the start time from it
        recording_path: Path = layout_path / folder / f"{camera_path.name}-{started_at:%Y%m%d-%H%M%S}-{recording['startTime']}000-7.mp4"
        recording_path.parent.mkdir()
        shutil.move(clip_path, recording_path)

        for path in sorted([path for path in layout_path.rglob("*") if path.is_file()], key=lambda path: path.suffix == ".mp4"):
            destination_path: Path = camera_path / path.relative_to(layout_path)
            destination_path.parent.mkdir(parents=True, exist_ok=True)
            path.rename(destination_path)


def save_recordings(mac: str) -> None:
    camera_path: Path = IMPORT_PATH / mac
    saved_path: Path = SAVED_PATH / mac

    camera_path.mkdir(exist_ok=True)
    saved_path.mkdir(parents=True, exist_ok=True)

    (camera_path / ".alias").write_text(latest[mac]["alias"])  # names the camera surveillance station adds for the folder

    tapo: Tapo = Tapo(find_camera_host(mac), "admin", PASSWORD, PASSWORD)  # the camera's local admin takes the cloud account's password
    tapo.getUserID()  # the downloader reads it inside its event loop, where pytapo can't request it; cache it first

    idle_since: float = time.time()
    while time.time() - max(idle_since, last_detected_at[mac]) < IDLE_SECONDS:
        # the camera downloads only from the day it listed last, so save each day's recordings right after listing them
        for day in [date.today() - timedelta(days=1), date.today()]:
            pending: list[dict[str, Any]] = [recording for recording in list_recordings(tapo, day) if not (saved_path / str(recording["startTime"])).exists()]
            for recording in pending:
                with tempfile.TemporaryDirectory() as temporary:
                    clip_path: Path = Path(temporary) / "recording.mp4"
                    action: str
                    downloaded_seconds: float
                    action, downloaded_seconds = download_recording(tapo, recording=recording, clip_path=clip_path)

                    # the camera still records while the detected motion goes on
                    if action == "Recording in progress":
                        idle_since = time.time()

                        continue

                    # the sd card can hold less video than the camera lists for a recording, and the downloader drops a clip that falls short; save the part the camera sends
                    if action == "Giving up" and downloaded_seconds > 0:
                        recording = {**recording, "endTime": recording["startTime"] + int(downloaded_seconds) - 1}
                        action, downloaded_seconds = download_recording(tapo, recording=recording, clip_path=clip_path)

                    # the downloader leaves no file when it gives up or finds the camera busy
                    if not clip_path.exists():
                        print(f"no clip for the {latest[mac]['alias']} recording at {datetime.fromtimestamp(recording['startTime'])} ({action}), retrying on the next poll", flush=True)  # journald gets a pipe, which python buffers until the run ends

                        continue

                    import_clip(clip_path, recording=recording, camera_path=camera_path)

                (saved_path / str(recording["startTime"])).touch()
                print(f"saved the {latest[mac]['alias']} recording at {datetime.fromtimestamp(recording['startTime'])}", flush=True)

                idle_since = time.time()

        time.sleep(POLL_SECONDS)


def start_saving(mac: str) -> None:
    last_detected_at[mac] = time.time()

    # save the camera's recordings from its sd card once it detects something, without waking a battery camera up otherwise; an unreachable camera fails only its thread, and its next detection starts another
    if mac not in savers or not savers[mac].is_alive():
        savers[mac] = threading.Thread(target=save_recordings, args=(mac,), daemon=True)  # a daemon, so that a failed cloud request still ends the process
        savers[mac].start()


def format_detection(*, camera: dict[str, Any], title: str) -> str:
    detected_at: datetime = datetime.fromtimestamp(int(camera["msgTime"]) / 1000)

    return f"{camera['alias']} ({camera['deviceModel']}): {title} at {detected_at:%Y-%m-%d %H:%M:%S}"


def report_detection(*, message_id: str, camera: dict[str, Any], title: str) -> None:
    # the history keeps the detections of a camera removed from the account
    if message_id in seen or camera["deviceId"] not in cameras:
        return

    seen[message_id] = int(camera["msgTime"])
    print(format_detection(camera=camera, title=title), flush=True)

    mac: str = cameras[camera["deviceId"]]
    latest[mac] = {"alias": camera["alias"], "detectedAt": int(camera["msgTime"])}
    LATEST_PATH.write_text(json.dumps(latest))
    start_saving(mac)

    DETECTIONS_PATH.write_text(json.dumps(seen))


# the tapo app's pushes are plain data messages, while the library handles only encrypted web pushes
class DetectionPushClient(FcmPushClient):
    def _handle_data_message(self, msg: DataMessageStanza) -> None:
        push: dict[str, str] = {entry.key: entry.value for entry in msg.app_data}

        if push.get("msgType") in DETECTION_TYPES:
            report_detection(message_id=push["msgId"], camera=push, title=push["title"])


async def read_history() -> None:
    since: int = max(max(seen.values(), default=0) - OVERLAP_MS, int(time.time() * 1000) - HISTORY_MS)
    detections: list[dict[str, Any]] = await asyncio.to_thread(fetch_detections, since)

    for detection in detections:
        report_detection(message_id=detection["msgId"], camera=detection["attachments"], title=detection["title"])

    newest: int = max(seen.values(), default=0)
    for message_id, detected_at in list(seen.items()):
        if detected_at < newest - OVERLAP_MS:
            del seen[message_id]

    DETECTIONS_PATH.write_text(json.dumps(seen))


async def watch_detections() -> None:
    await asyncio.to_thread(log_in)
    cameras.update(await asyncio.to_thread(fetch_cameras))
    export_cameras()
    await asyncio.to_thread(register_push)

    client: DetectionPushClient = DetectionPushClient(lambda *_: None, PUSH_CONFIG, {"gcm": {"android_id": ANDROID_ID, "security_token": SECURITY_TOKEN, "app_id": "com.tplink.iot"}})
    await client.start()

    # a restart cuts off saving the recordings of the latest detections
    for mac, detection in latest.items():
        if time.time() * 1000 - detection["detectedAt"] < RESUME_MS:
            start_saving(mac)

    history_read_at: float = 0
    while True:
        # the history catches the detections whose pushes went to a phone while it held the registration
        taken_back: bool = await asyncio.to_thread(hold_push_registration)
        if taken_back or time.monotonic() - history_read_at >= HISTORY_SECONDS:
            # a camera added in the app gets no pushes until it is subscribed
            fetched: dict[str, str] = await asyncio.to_thread(fetch_cameras)
            if fetched != cameras:
                cameras.clear()
                cameras.update(fetched)
                export_cameras()
                await asyncio.to_thread(register_push)

            await read_history()
            history_read_at = time.monotonic()

        await asyncio.sleep(REGISTRATION_SECONDS)


def main() -> None:
    asyncio.run(watch_detections())


if __name__ == "__main__":
    main()
