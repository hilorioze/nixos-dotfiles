{config, ...}: let
  webrtcPortRange = {
    from = 61000;
    to = 61009;
  };
in {
  networking.firewall.allowedUDPPortRanges = [webrtcPortRange];

  sops = {
    secrets."services/neko/password" = {};

    templates."services/neko.env".content = ''
      # keep-sorted start
      NEKO_MEMBER_MULTIUSER_ADMIN_PASSWORD=${config.sops.placeholder."services/neko/password"}
      NEKO_MEMBER_MULTIUSER_USER_PASSWORD=${config.sops.placeholder."services/neko/password"}
      # keep-sorted end
    '';
  };

  virtualisation.oci-containers.containers.neko = let
    webrtcPortRangeString = "${toString webrtcPortRange.from}-${toString webrtcPortRange.to}";
  in {
    image = "ghcr.io/m1k1o/neko/firefox@sha256:0e0dfa8199ff4cccf95284c0c8e9dde72f740feb816302cc5e7071efe079039e"; # 3.1.4

    environmentFiles = ["${config.sops.templates."services/neko.env".path}"];
    environment = {
      NEKO_SERVER_PROXY = "true";

      NEKO_WEBRTC_EPR = webrtcPortRangeString;
      NEKO_WEBRTC_ICELITE = "true";
    };

    labels = {
      "traefik.enable" = "true";

      "traefik.http.routers.neko.entryPoints" = "https";
      "traefik.http.routers.neko.rule" = "Host(`neko.${config.networking.fqdn}`)";

      "traefik.http.services.neko.loadBalancer.server.port" = "8080";
    };

    ports = ["${webrtcPortRangeString}:${webrtcPortRangeString}/udp"];

    volumes = ["neko-firefox:/home/neko/.mozilla/firefox"];
  };
}
