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

    [device-settings.f226946857a3141b80fefa0bae8de91cdba1c6eedf91d96ea7bef76ce88b4e90]
    sync = { lighting = { mode = "static", colors = [[0, 71, 255]] } }
  '';
in {
  imports = [../../common/features/coolercontrol.nix];

  system.activationScripts.installCoolercontrolConfig = {
    deps = ["etc"];

    text = ''
      ${lib.getExe' pkgs.coreutils "install"} \
        -Dm0644 \
        ${coolercontrolConfig} \
        /etc/coolercontrol/config.toml
    '';
  };

  systemd.services.coolercontrold.restartTriggers = [coolercontrolConfig];
}
