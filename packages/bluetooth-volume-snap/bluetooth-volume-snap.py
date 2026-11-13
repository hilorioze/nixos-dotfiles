import argparse
import asyncio
from typing import Any, cast

from dbus_fast import BusType, Message, Variant
from dbus_fast.aio import MessageBus

AVRCP_VOLUME_MAX: int = 127


def parse_arguments() -> argparse.Namespace:
    parser: argparse.ArgumentParser = argparse.ArgumentParser()
    parser.add_argument("--address", required=True)
    parser.add_argument("--step", type=int, required=True)

    return parser.parse_args()


def snap_volume(*, volume: int, step: int) -> int:
    # pipewire shows an avrcp volume as the same share of 100%
    percent: float = volume * 100 / AVRCP_VOLUME_MAX
    snapped_percent: int = round(percent / step) * step

    # the nearest multiple of a step that doesn't divide 100 can lie above 100%
    return min(round(snapped_percent * AVRCP_VOLUME_MAX / 100), AVRCP_VOLUME_MAX)


def build_match_rule(device_path: str) -> str:
    return f"type='signal',sender='org.bluez',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged',path_namespace='{device_path}'"


async def call_bluez(*, system_bus: MessageBus, path: str, interface: str, member: str, signature: str = "", body: list[Any] | None = None) -> list[Any]:
    reply: Message = await system_bus.call(Message(destination="org.bluez", path=path, interface=interface, member=member, signature=signature, body=body or []))

    return reply.body


async def list_transports(*, system_bus: MessageBus, device_path: str) -> list[str]:
    objects: dict[str, dict[str, dict[str, Variant]]] = (await call_bluez(system_bus=system_bus, path="/", interface="org.freedesktop.DBus.ObjectManager", member="GetManagedObjects"))[0]

    return [path for path, interfaces in objects.items() if path.startswith(f"{device_path}/") and "org.bluez.MediaTransport1" in interfaces]


async def snap_transport(*, system_bus: MessageBus, path: str, step: int) -> None:
    properties: dict[str, Variant] = (await call_bluez(system_bus=system_bus, path=path, interface="org.freedesktop.DBus.Properties", member="GetAll", signature="s", body=["org.bluez.MediaTransport1"]))[0]

    # the device applies an absolute volume only while the transport streams
    if properties["State"].value != "active":
        return

    volume: int = properties["Volume"].value
    snapped: int = snap_volume(volume=volume, step=step)
    if snapped == volume:
        return

    await call_bluez(system_bus=system_bus, path=path, interface="org.freedesktop.DBus.Properties", member="Set", signature="ssv", body=["org.bluez.MediaTransport1", "Volume", Variant("q", snapped)])


def handle_signal(message: Message, *, system_bus: MessageBus, step: int) -> None:
    if message.member != "PropertiesChanged":
        return

    interface: str = message.body[0]
    changed: dict[str, Variant] = message.body[1]

    # snap a volume the device changed itself, and one it couldn't take while the transport was idle
    if interface == "org.bluez.MediaTransport1" and ("State" in changed or "Volume" in changed):
        path: str = cast(str, message.path)  # dbus signals always carry an object path

        asyncio.get_running_loop().create_task(snap_transport(system_bus=system_bus, path=path, step=step))


async def run(*, address: str, step: int) -> None:
    device_path: str = f"/org/bluez/hci0/dev_{address.replace(':', '_')}"

    system_bus: MessageBus = await MessageBus(bus_type=BusType.SYSTEM).connect()

    system_bus.add_message_handler(lambda message: handle_signal(message, system_bus=system_bus, step=step))
    await system_bus.call(Message(destination="org.freedesktop.DBus", path="/org/freedesktop/DBus", interface="org.freedesktop.DBus", member="AddMatch", signature="s", body=[build_match_rule(device_path)]))

    for path in await list_transports(system_bus=system_bus, device_path=device_path):
        await snap_transport(system_bus=system_bus, path=path, step=step)

    await system_bus.wait_for_disconnect()


def main() -> None:
    arguments: argparse.Namespace = parse_arguments()

    asyncio.run(run(address=arguments.address, step=arguments.step))


if __name__ == "__main__":
    main()
