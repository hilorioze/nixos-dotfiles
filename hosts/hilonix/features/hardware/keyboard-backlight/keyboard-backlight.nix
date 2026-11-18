{pkgs, ...}: let
  keyboardBacklightControl = pkgs.writers.writePython3 "keyboard-backlight-control" {
    doCheck = false; # treefmt lints the script with ruff
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

  systemd = {
    # after a resume the keyboard keeps a new effect dark until it has been up for a while, and nothing tells when; set it once more a bit later
    timers.keyboard-backlight = {
      description = "Keyboard backlight repeat";

      wantedBy = ["displays-on.target"];

      partOf = ["displays-on.target"]; # displays turned off in the meantime cancel the repeat

      timerConfig = {
        OnActiveSec = "3s";

        RemainAfterElapse = false; # the next turn-on starts it again
      };
    };

    services = {
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
  };
}
