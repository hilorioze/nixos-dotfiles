let
  stateDirectory = "/var/lib/cowrie";

  uid = "999"; # the image's `cowrie` user
in {
  virtualisation.oci-containers.containers.cowrie = {
    image = "docker.io/cowrie/cowrie:3.1.7@sha256:e7c4b4fe5fbb874e682c6c0c7a1daf1c3183c622d5cc2d281f453c1c4d9f97ac";

    environment = {
      COWRIE_HONEYPOT_HOSTNAME = "web01"; # the default `svr04` gives cowrie away

      COWRIE_TELNET_ENABLED = "true";

      COWRIE_TELNET_CVE_2026_24061_VULNERABLE = "true"; # let the inetutils telnetd `USER=-f` exploit land in a shell
    };

    ports = [
      # keep-sorted start
      "22:2222"
      "23:2223"
      # keep-sorted end
    ];

    volumes = ["${stateDirectory}:/cowrie/cowrie-git/var"];
  };

  systemd = {
    # the bind mount hides the image's directories, and cowrie doesn't create them
    tmpfiles.rules = [
      # keep-sorted start
      "d ${stateDirectory}/lib/cowrie 0755 ${uid} ${uid} -"
      "d ${stateDirectory}/lib/cowrie/downloads 0755 ${uid} ${uid} -"
      "d ${stateDirectory}/lib/cowrie/tty 0755 ${uid} ${uid} -"
      "d ${stateDirectory}/log/cowrie 0755 ${uid} ${uid} -"
      # keep-sorted end
    ];

    services.honeypot-reporter.environment.COWRIE_LOG = "${stateDirectory}/log/cowrie/cowrie.json";
  };
}
