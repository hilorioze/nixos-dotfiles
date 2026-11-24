{pkgs, ...}: let
  keyboardBacklightControl = pkgs.writers.writePython3 "keyboard-backlight-control" {
    doCheck = false; # treefmt lints the script with ruff
  } (builtins.readFile ./keyboard-backlight-control.py);

  keyboardVendorId = "1532";
  keyboardProductId = "025e";

  keyboardBacklightColor = "00ffff";
  keyboardBacklightBrightness = 122; # 0..255
in {
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ENV{ID_VENDOR_ID}=="${keyboardVendorId}", ENV{ID_MODEL_ID}=="${keyboardProductId}", ENV{ID_USB_INTERFACE_NUM}=="02", TAG+="systemd", ENV{SYSTEMD_WANTS}+="keyboard-backlight-store.service"
  '';

  systemd.services = {
    # the keyboard keeps the static effect and the brightness in its own memory and starts with them; set them once per connection
    keyboard-backlight-store.serviceConfig = {
      Type = "oneshot";

      ExecStart = "${keyboardBacklightControl} store --color ${keyboardBacklightColor} --brightness ${toString keyboardBacklightBrightness}";
    };

    keyboard-backlight = {
      wantedBy = ["displays-on.target"];

      partOf = ["displays-on.target"]; # displays turning off stop the frames

      serviceConfig.ExecStart = "${keyboardBacklightControl} show --color ${keyboardBacklightColor} --repeat-interval 1"; # custom frames stay in the keyboard's ram, so repeating them doesn't wear its flash
    };

    keyboard-backlight-off = {
      wantedBy = ["displays-off.target"];

      after = ["keyboard-backlight.service"]; # the frames stop before the black one, so the keyboard ends up dark

      serviceConfig = {
        Type = "oneshot";

        ExecStart = "${keyboardBacklightControl} show --color 000000";
      };
    };
  };
}
