{
  imports = [../../common/features/traefik.nix];

  networking.firewall.allowedTCPPorts = [
    # keep-sorted start numeric=yes
    5000
    5001
    # keep-sorted end
  ];

  services.traefik.staticConfigOptions.entryPoints = {
    # keep-sorted start block=yes newline_separated=yes numeric=yes by_regex=address\s*=\s*[^;]*?:(\d+)
    dsm-http.address = ":5000";

    dsm-https.address = ":5001";
    # keep-sorted end
  };
}
