{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  auraControllerUid = "f226946857a3141b80fefa0bae8de91cdba1c6eedf91d96ea7bef76ce88b4e90";

  caseLighting = {
    mode = "static";

    colors = [[0 32 32]]; # the controller has no brightness setting, so the color itself is dimmed: this is [0, 255, 255] at 1/8
  };

  coolercontrolConfig = pkgs.writeText "coolercontrol-config.toml" ''
    # coolercontrold fails to load the config if `[settings]` is missing
    [settings]

    # coolercontrold panics if `[legacy690]` is missing
    [legacy690]

    [device-settings.${auraControllerUid}]
    sync = { lighting = { mode = "${caseLighting.mode}", colors = ${builtins.toJSON caseLighting.colors} } }
  '';

  # retry while coolercontrold is still starting at boot and doesn't know the controller yet
  setCaseLighting = lighting: "${lib.getExe pkgs.curl} --silent --show-error --fail --retry 10 --retry-all-errors --config ${config.sops.templates."services/case-lighting/curlrc".path} --request PUT --json '${builtins.toJSON lighting}' http://127.0.0.1:11987/devices/${auraControllerUid}/settings/sync/lighting";
in {
  imports = [../../common/features/coolercontrol.nix];

  sops = {
    secrets = {
      # keep-sorted start
      "services/case-lighting/coolercontrol-token" = {};
      "services/coolercontrol/tokens/case-lighting/hashed-token" = {};
      # keep-sorted end
    };

    templates = {
      "services/coolercontrol/tokens.json" = {
        content = builtins.toJSON [
          {
            id = "case-lighting";
            label = "case-lighting";

            hash = config.sops.placeholder."services/coolercontrol/tokens/case-lighting/hashed-token";

            write_access = true;

            created_at = "1970-01-01T00:00:00Z"; # coolercontrold requires it
          }
        ];

        path = "/etc/coolercontrol/.tokens";

        restartUnits = ["coolercontrold.service"];
      };

      "services/case-lighting/curlrc".content = ''
        header = "Authorization: Bearer ${config.sops.placeholder."services/case-lighting/coolercontrol-token"}"
      '';
    };
  };

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

  systemd.services = {
    coolercontrold.restartTriggers = [coolercontrolConfig];

    case-lighting = {
      description = "Case lighting";

      wantedBy = ["displays-on.target"];

      after = ["coolercontrold.service"];

      serviceConfig = {
        Type = "oneshot";

        ExecStart = setCaseLighting caseLighting;
      };
    };

    case-lighting-off = {
      description = "Case lighting off";

      wantedBy = ["displays-off.target"];

      after = ["coolercontrold.service"];

      serviceConfig = {
        Type = "oneshot";

        ExecStart = setCaseLighting {
          mode = "off";

          colors = [];
        };
      };
    };
  };
}
