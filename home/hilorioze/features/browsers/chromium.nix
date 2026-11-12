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
  home.activation.setKeePassXCBrowserStorage = let
    storagePath = "${config.home.homeDirectory}/.config/chromium/Default/Local Extension Settings/${pkgs.chromium-extension-keepassxc-browser.id}";

    writeStorage =
      pkgs.writers.writePython3 "write-chromium-extension-storage" {
        libraries = [pkgs.python3Packages.plyvel];

        flakeIgnore = (import ../../../../shared.nix).ignoredFlake8Rules;
      } /* python */ ''
        import json
        import sys

        import plyvel


        def main() -> None:
            storage_path: str = sys.argv[1]
            values_path: str = sys.argv[2]

            with open(values_path) as file:
                values: dict[str, object] = json.load(file)

            # a running chromium holds the storage lock; the values are written on the next activation with chromium closed
            try:
                database: plyvel.DB = plyvel.DB(storage_path, create_if_missing=True)
            except plyvel.IOError:
                print("chromium is running, skipping the keepassxc-browser storage", file=sys.stderr)
                return

            with database.write_batch() as batch:
                for key, value in values.items():
                    batch.put(key.encode(), json.dumps(value, separators=(",", ":")).encode())

            database.close()


        if __name__ == "__main__":
            main()
      '';
  in
    lib.hm.dag.entryAfter ["sops-nix"] ''
      mkdir --parents ${lib.escapeShellArg (builtins.dirOf storagePath)}

      ${writeStorage} ${lib.escapeShellArg storagePath} ${config.sops.templates."apps/keepassxc-browser/chromium/storage.json".path}
    '';
}
