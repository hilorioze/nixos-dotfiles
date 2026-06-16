{
  virtualisation.oci-containers.containers.ftbie = {
    image = "ghcr.io/itzg/minecraft-server:2026.6.0-java8@sha256:ebea5547ff3d40e51dc61eb3056d1c4d314507e0f356a770715477f0b533bc8b";

    environment = {
      EULA = "TRUE";

      MEMORY = "6G";

      ONLINE_MODE = "FALSE";

      TYPE = "FTBA"; # Feed the Beast App; "FTB" used to be a CurseForge alias

      FTB_MODPACK_ID = "23"; # FTB Infinity Evolved 1.7
      FTB_MODPACK_VERSION_ID = "99"; # 3.1.0
    };

    ports = ["25565:25565"];

    volumes = ["ftbie:/data"];
  };
}
