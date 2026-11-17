{pkgs, ...}: let
  keyboardBacklightControl = pkgs.writers.writePython3 "keyboard-backlight-control" {
    flakeIgnore = (import ../../../../../shared.nix).ignoredFlake8Rules;
  } (builtins.readFile ./keyboard-backlight-control.py);

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
