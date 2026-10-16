{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  coolercontrolConfig = pkgs.writeText "coolercontrol-config.toml" ''
    # coolercontrold fails to load the config if `[settings]` is missing
    [settings]

    # coolercontrold panics if `[legacy690]` is missing
    [legacy690]

    # the controller has no brightness setting, so the color itself is dimmed: this is [0, 255, 255] at 1/8
    [device-settings.f226946857a3141b80fefa0bae8de91cdba1c6eedf91d96ea7bef76ce88b4e90]
    sync = { lighting = { mode = "static", colors = [[0, 32, 32]] } }
  '';
in {
  imports = [../../common/features/coolercontrol.nix];

  system.activationScripts.installCoolercontrolConfig = {
    deps = ["etc"];

    text = ''
      ${lib.getExe' pkgs.coreutils "install"} \
        -D \
        --mode=0644 \
        ${coolercontrolConfig} \
        /etc/coolercontrol/config.toml
    '';
  };

  systemd.services.coolercontrold.restartTriggers = [coolercontrolConfig];
}
