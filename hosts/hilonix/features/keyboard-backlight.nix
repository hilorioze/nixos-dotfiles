{pkgs, ...}: let
  keyboardBacklightControl =
    pkgs.writers.writePython3 "keyboard-backlight-control" {
      flakeIgnore = (import ../../../shared.nix).ignoredFlake8Rules;
    } ''
      import argparse

      REPORT_ID: int = 0x06
      REPORT_SIZE: int = 32

      PACKET_HEADER: int = 0xBE

      LIGHT_EFFECT_SET_COMMAND: int = 0x15

      CURRENT_DEVICE: int = 0
      CUSTOM_PROFILE: int = 1

      STATIC_MODE: int = 2

      PALETTE_SIZE: int = 4


      def build_packet(*, command: int, data: bytes) -> bytes:
          status: int = 0

          packet: bytes = bytes([REPORT_ID, PACKET_HEADER, command, status]) + data

          return packet.ljust(REPORT_SIZE, b"\x00")


      def build_palette(*, color: bytes) -> bytes:
          flags: int = 0

          entry: bytes = color + bytes([flags])

          palette: bytes = entry.ljust(PALETTE_SIZE * len(entry), b"\x00")

          return palette


      def build_static_packet(*, color: bytes, brightness: int) -> bytes:
          speed: int = 0
          direction: int = 0

          settings: bytes = bytes([CURRENT_DEVICE, CUSTOM_PROFILE, STATIC_MODE, speed, brightness, direction])

          data: bytes = settings + bytes(2) + build_palette(color=color)

          packet: bytes = build_packet(command=LIGHT_EFFECT_SET_COMMAND, data=data)

          return packet


      def parse_arguments() -> argparse.Namespace:
          parser: argparse.ArgumentParser = argparse.ArgumentParser()
          parser.add_argument("--device", required=True)
          parser.add_argument("--color", type=bytes.fromhex, required=True)
          parser.add_argument("--brightness", type=int, required=True)

          arguments: argparse.Namespace = parser.parse_args()

          return arguments


      def write_packet(*, device: str, packet: bytes) -> None:
          with open(device, "wb", buffering=0) as hidraw:
              hidraw.write(packet)


      def main() -> None:
          arguments: argparse.Namespace = parse_arguments()

          packet: bytes = build_static_packet(color=arguments.color, brightness=arguments.brightness)

          write_packet(device=arguments.device, packet=packet)


      if __name__ == "__main__":
          main()
    '';

  keyboardVendorId = "0416";
  keyboardProductId = "a0f8";

  keyboardDevice = "/dev/input/by-id/usb-_HATOR_gaming_keyboard_WKB-F202BENTUB-if01-hidraw";

  keyboardBacklightColor = "00ffff";
  keyboardBacklightBrightness = 3; # 0..6; 0, 16, 32, 48, 65, 84, 100 percent respectively
in {
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ENV{ID_VENDOR_ID}=="${keyboardVendorId}", ENV{ID_MODEL_ID}=="${keyboardProductId}", ENV{ID_USB_INTERFACE_NUM}=="01", TAG+="systemd", ENV{SYSTEMD_WANTS}+="keyboard-backlight.service"
  '';

  systemd.services.keyboard-backlight = {
    description = "Keyboard backlight";

    serviceConfig = {
      Type = "oneshot";

      ExecStart = "${keyboardBacklightControl} --device ${keyboardDevice} --color ${keyboardBacklightColor} --brightness ${toString keyboardBacklightBrightness}";
    };
  };
}
