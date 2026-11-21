{
  virtualisation.oci-containers.containers.ftbie = {
    image = "ghcr.io/itzg/minecraft-server:2026.11.0-java8@sha256:91c8edad666c51ce0148022931dac327c973e6d8084cddb0e9090e2c60622f9c";

    environment = {
      EULA = "TRUE";

      MEMORY = "6G";

      ONLINE_MODE = "FALSE";

      TYPE = "FTBA"; # "Feed the Beast App"; "FTB" used to be a curseforge alias

      FTB_MODPACK_ID = "23"; # "FTB Infinity Evolved 1.7"
      FTB_MODPACK_VERSION_ID = "99"; # 3.1.0

      OPS = "80cf2d45-be52-358a-a7ba-26fe414d560c"; # hiloriozeoffline

      LEVEL_TYPE = "BIOMESOP";
    };

    ports = ["25565:25565"];

    volumes = ["ftbie:/data"];

    extraOptions = [
      # podman drops the image's `HEALTHCHECK` from oci-format images; repeat it here
      "--health-cmd=mc-health"
      "--health-interval=30s"
      "--health-retries=2"

      # startup takes about 3 minutes; delay health check failures until it finishes
      "--health-start-period=4m"

      "--stop-timeout=90" # the image waits up to 60s for the world to save after `stop`; podman's default 10s kills it mid-save and loses `level.dat`
    ];
  };
}
