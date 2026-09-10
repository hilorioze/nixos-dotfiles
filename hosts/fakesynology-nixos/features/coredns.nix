{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  services = {
    resolved.settings.Resolve = {
      DNSStubListener = false; # free `:53` for CoreDNS listening globally
      DNSStubListenerExtra = "127.0.0.1:1053"; # keep available locally on a non-conflicting port
    };

    coredns = {
      enable = true;

      config = let
        domain = config.networking.domain;

        lanHostNames = [
          # keep-sorted start
          "cex"
          "fakesynology"
          "fakesynology-nixos"
          # keep-sorted end
        ];

        mkLanTarget = hostName:
          if hostName == config.networking.hostName
          then "_outbound"
          else "${hostName}.local";
      in ''
        . {
          # `fakesynology.${domain}` -> `fakesynology.local`
          ${lib.concatMapStringsSep "\n" (
            hostName: "rewrite stop name exact ${hostName}.${domain}. ${mkLanTarget hostName}."
          )
          lanHostNames}

          # `immich.fakesynology.${domain}` -> CNAME (public DNS) `fakesynology.${domain}` -> `fakesynology.local`
          ${lib.concatMapStringsSep "\n" (
            hostName: "rewrite continue cname exact ${hostName}.${domain}. ${mkLanTarget hostName}."
          )
          lanHostNames}

          forward _outbound. ${config.services.resolved.settings.Resolve.DNSStubListenerExtra} # avoid self-resolution to irrelevant addresses
          forward local. ${config.services.resolved.settings.Resolve.DNSStubListenerExtra}

          forward . 1.1.1.1 1.0.0.1 # chosen as the best-performing resolvers

          cache
        }
      '';
    };
  };

  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 127.0.0.1
  '';
}
