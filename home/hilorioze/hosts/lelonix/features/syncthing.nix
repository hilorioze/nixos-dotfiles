{config, ...}: {
  services.syncthing.settings.folders."Sync" = {
    path = "${config.home.homeDirectory}/Sync";

    devices = [
      # keep-sorted start
      "hilonix"
      "philone"
      # keep-sorted end
    ];
  };
}
