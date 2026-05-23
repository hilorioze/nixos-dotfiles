{
  # keep-sorted start
  config,
  # keep-sorted end
  ...
}: {
  services.syncthing.settings.folders."Sync" = {
    path = "${config.home.homeDirectory}/Sync";

    devices = [
      # keep-sorted start
      "lelonix"
      "philone"
      # keep-sorted end
    ];
  };
}
