{pkgs, ...}: let
  keyboardBacklightControl =
    pkgs.writers.writePython3 "keyboard-backlight-control" {
      flakeIgnore = (import ../../../../shared.nix).ignoredFlake8Rules;
    } /* python */ ''
      import argparse
      from pathlib import Path

      DRIVER_PATH: Path = Path("/sys/bus/hid/drivers/razerkbd")


      def parse_arguments() -> argparse.Namespace:
          parser: argparse.ArgumentParser = argparse.ArgumentParser()
          parser.add_argument("--color", type=bytes.fromhex, required=True)
          parser.add_argument("--brightness", type=int, required=True)

          arguments: argparse.Namespace = parser.parse_args()

          return arguments


      def find_device() -> Path:
          # of the keyboard's interfaces only the lighting one has the `matrix_*` attributes
          return next(DRIVER_PATH.glob("*/matrix_brightness")).parent


      def set_backlight(*, device: Path, color: bytes, brightness: int) -> None:
          (device / "matrix_effect_static").write_bytes(color)
          (device / "matrix_brightness").write_text(str(brightness))


      def main() -> None:
          arguments: argparse.Namespace = parse_arguments()

          device: Path = find_device()

          set_backlight(device=device, color=arguments.color, brightness=arguments.brightness)


      if __name__ == "__main__":
          main()
    '';

  keyboardVendorId = "1532";
  keyboardProductId = "025e";

  keyboardBacklightColor = "00ffff";
  keyboardBacklightBrightness = 122; # 0..255

  keyboardBacklightControlCommand = "${keyboardBacklightControl} --color ${keyboardBacklightColor}";
in {
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ENV{ID_VENDOR_ID}=="${keyboardVendorId}", ENV{ID_MODEL_ID}=="${keyboardProductId}", ENV{ID_USB_INTERFACE_NUM}=="02", TAG+="systemd", ENV{SYSTEMD_WANTS}+="keyboard-backlight.service"
  '';

  systemd.services = {
    keyboard-backlight = {
      description = "Keyboard backlight";

      wantedBy = ["displays-on.target"];

      serviceConfig = {
        Type = "oneshot";

        ExecStart = "${keyboardBacklightControlCommand} --brightness ${toString keyboardBacklightBrightness}";
      };
    };

    keyboard-backlight-off = {
      description = "Keyboard backlight off";

      wantedBy = ["displays-off.target"];

      serviceConfig = {
        Type = "oneshot";

        ExecStart = "${keyboardBacklightControlCommand} --brightness 0";
      };
    };
  };
}
