{
  imports = [../../common/features/podman.nix];

  services.postgresql = {
    enableTCPIP = true;

    # `podman0` bridge subnet for local containers
    authRules = ["host all all 10.88.0.0/16 scram-sha-256"];
  };
}
