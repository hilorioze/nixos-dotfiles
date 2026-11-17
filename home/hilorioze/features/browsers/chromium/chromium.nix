{
  # keep-sorted start
  config,
  lib,
  osConfig,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops = {
    secrets."apps/keepassxc-browser/chromium/key" = {};

    templates."apps/keepassxc-browser/chromium/storage.json".content = let
      databaseHash = "fb9a50b4543f9ff95e065ab937916c5e73980e49282a82fab075608bfb382e89";
    in
      builtins.toJSON {
        keyRing.${databaseHash} = {
          id = "chromium@${osConfig.networking.hostName}";

          hash = databaseHash;

          key = config.sops.placeholder."apps/keepassxc-browser/chromium/key";
        };

        settings = {
          autoFillAndSend = true;

          downloadFaviconAfterSave = true;

          passkeys = true;
        };
      };
  };

  programs.chromium = {
    enable = true;

    package = pkgs.ungoogled-chromium;

    # ungoogled-chromium never updates extensions from the web store; install the pinned crx files that `update-packages.yaml` keeps current
    extensions =
      map (crx: {
        inherit (crx) id;

        inherit (crx) version;

        crxPath = crx;
      }) [
        # keep-sorted start
        pkgs.chromium-extension-keepassxc-browser
        pkgs.chromium-extension-playwright
        pkgs.chromium-extension-synclify
        pkgs.chromium-extension-ublock-origin-lite
        # keep-sorted end
      ];
  };

  # chromium keeps `chrome.storage.local` in leveldb instead of a file like librewolf's `storage.js`, so put the template's values there
  systemd.user.services.chromium-keepassxc-browser-storage = let
    storagePath = "${config.home.homeDirectory}/.config/chromium/Default/Local Extension Settings/${pkgs.chromium-extension-keepassxc-browser.id}";

    writeStorage = pkgs.writers.writePython3 "write-chromium-extension-storage" {
      libraries = [pkgs.python3Packages.plyvel];

      doCheck = false; # treefmt lints the script with ruff
    } (builtins.readFile ./write-chromium-extension-storage.py);
  in {
    Install.WantedBy = ["sops-nix.service"]; # sops-nix renders the template only in a running user session, so rewrite the storage each time it does

    Unit.After = ["sops-nix.service"];

    Service = {
      Type = "oneshot";

      ExecStartPre = "${lib.getExe' pkgs.coreutils "mkdir"} --parents ${lib.escapeShellArg (builtins.dirOf storagePath)}";
      ExecStart = "${writeStorage} ${lib.escapeShellArg storagePath} ${config.sops.templates."apps/keepassxc-browser/chromium/storage.json".path}";
    };
  };
}
