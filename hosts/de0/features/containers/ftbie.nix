{
  virtualisation.oci-containers.containers.ftbie = {
    image = "ghcr.io/itzg/minecraft-server:2026.10.1-java8@sha256:e96f581be09a8760487c48302f6f953cee3eeb06b00efe637f2a582ea38067ec";

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

    # startup takes about 3 minutes; delay health check failures until it finishes
    extraOptions = ["--health-start-period=4m"];
  };
}
