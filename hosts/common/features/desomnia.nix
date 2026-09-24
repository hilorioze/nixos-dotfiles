{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  environment.etc."desomnia/monitor.xml".source = let
    wivrnPort = 9757;

    networkServices =
      map (port: {
        name = "SSH";
        protocol = "TCP";

        inherit port;
      })
      config.services.openssh.ports
      ++ [
        {
          name = "WiVRn";
          protocol = "TCP";
          port = wivrnPort;
        }
        {
          name = "WiVRn";
          protocol = "UDP";
          port = wivrnPort;
        }
      ];
  in
    lib.mkDefault (pkgs.replaceVars ./desomnia-monitor-host.xml {
      serviceEntries =
        lib.concatMapStringsSep "\n    " (
          service: "<Service name=\"${service.name}\" protocol=\"${service.protocol}\" port=\"${toString service.port}\"/>"
        )
        networkServices;
    });

  systemd.services.desomnia = {
    description = "Desomnia intelligent power management";

    wantedBy = ["multi-user.target"];

    after = ["network-online.target"];

    wants = ["network-online.target"];

    path = with pkgs; [
      # keep-sorted start
      ethtool
      iproute2
      # keep-sorted end
    ];

    serviceConfig = {
      ExecStart = "${lib.getExe pkgs.desomnia} --auto-reload";

      Restart = "always";
      RestartSec = 5;
    };
  };
}
