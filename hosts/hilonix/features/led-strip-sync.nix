{
  lib,
  pkgs,
  ...
}: let
  ledStripControl =
    pkgs.writers.writePython3 "led-strip-control" {
      libraries = [pkgs.python3Packages.bleak];

      flakeIgnore = (import ../../../shared.nix).ignoredFlake8Rules;
    } ''
      import argparse
      import asyncio

      from bleak import BleakClient
      from bleak.backends.bluezdbus.manager import BlueZManager, get_global_bluez_manager
      from bleak.exc import BleakBluetoothNotAvailableError

      STRIP_WRITE_UUID: str = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

      PACKET_HEADER: int = 0x55

      POWER_GROUP: int = 0x01
      POWER_SET_COMMAND: int = 0x02

      BRIGHTNESS_GROUP: int = 0x03
      BRIGHTNESS_SET_COMMAND: int = 0x01

      COLOR_GROUP: int = 0x07
      COLOR_SET_COMMAND: int = 0x01


      def build_packet(*, group: int, command: int, data: bytes) -> bytes:
          packet: bytes = bytes([PACKET_HEADER, group, command]) + data

          return packet


      def build_power_packet(*, on: bool) -> bytes:
          data: bytes = bytes([on])

          packet: bytes = build_packet(group=POWER_GROUP, command=POWER_SET_COMMAND, data=data)

          return packet


      def build_color_packet(*, color: bytes) -> bytes:
          packet: bytes = build_packet(group=COLOR_GROUP, command=COLOR_SET_COMMAND, data=color)

          return packet


      def build_brightness_packet(*, brightness: int) -> bytes:
          data: bytes = brightness.to_bytes(2, "little")

          packet: bytes = build_packet(group=BRIGHTNESS_GROUP, command=BRIGHTNESS_SET_COMMAND, data=data)

          return packet


      def parse_arguments() -> argparse.Namespace:
          parser: argparse.ArgumentParser = argparse.ArgumentParser()
          parser.add_argument("--address", required=True)

          states = parser.add_subparsers(dest="state", required=True)

          on: argparse.ArgumentParser = states.add_parser("on")
          on.add_argument("--color", type=bytes.fromhex, required=True)
          on.add_argument("--brightness", type=int, required=True)

          states.add_parser("off")

          arguments: argparse.Namespace = parser.parse_args()

          return arguments


      async def wait_for_adapter() -> None:
          manager: BlueZManager = await get_global_bluez_manager()

          while True:
              try:
                  manager.get_default_adapter()
              except BleakBluetoothNotAvailableError:
                  await asyncio.sleep(0.1)
              else:
                  return


      async def send_packets(*, address: str, packets: list[bytes]) -> None:
          # bluetoothd registers and powers the adapter a moment after its own start and after each resume
          await wait_for_adapter()

          async with BleakClient(address) as client:
              for packet in packets:
                  await client.write_gatt_char(STRIP_WRITE_UUID, packet, response=False)
                  await asyncio.sleep(0.05)


      def main() -> None:
          arguments: argparse.Namespace = parse_arguments()

          packets: list[bytes]
          match arguments.state:
              case "on":
                  packets = [
                      build_power_packet(on=True),
                      build_color_packet(color=arguments.color),
                      build_brightness_packet(brightness=arguments.brightness),
                  ]
              case "off":
                  packets = [build_power_packet(on=False)]

          asyncio.run(send_packets(address=arguments.address, packets=packets))


      if __name__ == "__main__":
          main()
    '';

  ledStripAddress = "24:10:31:04:24:F1";

  ledStripColor = "00ffff";
  ledStripBrightness = 620; # app's range is 620..4095, the strip itself accepts 0..4095 and is still lit at 0

  ledStripControlCommand = "${ledStripControl} --address ${ledStripAddress}";

  ledStripTurnOnCommand = "${ledStripControlCommand} on --color ${ledStripColor} --brightness ${toString ledStripBrightness}";
  ledStripTurnOffCommand = "${ledStripControlCommand} off";

  ledStripService = {
    environment.BLEAK_LOGGING = "1"; # temporary: scan, connect, write and disconnect timings in the journal until the slow resume is found

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
in {
  systemd.services = {
    led-strip-power-sync = lib.mkMerge [
      ledStripService
      {
        description = "LED strip follows the power state";

        wantedBy = ["multi-user.target"];

        after = ["bluetooth.service"]; # also stops it before bluetooth goes down on shutdown

        serviceConfig = {
          ExecStart = ledStripTurnOnCommand;
          ExecStop = ledStripTurnOffCommand;
        };
      }
    ];

    led-strip-sleep-sync = lib.mkMerge [
      ledStripService
      {
        description = "LED strip follows the sleep state";

        wantedBy = ["sleep.target"];

        before = ["sleep.target"];

        unitConfig.StopWhenUnneeded = true; # runs `ExecStop` once `sleep.target` is stopped on resume

        serviceConfig = {
          ExecStart = ledStripTurnOffCommand;
          ExecStop = ledStripTurnOnCommand;
        };
      }
    ];
  };
}
