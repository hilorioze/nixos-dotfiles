{
  # servers only: `podman system prune` also removes stopped containers, which on desktops can be toolboxes kept on purpose
  virtualisation.podman.autoPrune = {
    enable = true;

    flags = ["--all"]; # oci-containers pull a new image on every update; without `--all` the replaced ones stay tagged and pile up
  };
}
