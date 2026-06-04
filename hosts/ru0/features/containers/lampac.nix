{pkgs, ...}: {
  virtualisation.oci-containers.containers.lampac = {
    image = "ghcr.io/lampac-nextgen/lampac@sha256:fae95162339be4bcce86d52e8cf7eb45998ed80dd7faab8aa974df68bf5f0e42"; # 1.32.1

    volumes = [
      "${pkgs.writeText "lampac-passwd" ""}:/lampac/passwd:ro"
      "lampac-cache:/lampac/cache"
      "lampac-database:/lampac/database"
    ];

    extraOptions = ["--network=host"];
  };
}
