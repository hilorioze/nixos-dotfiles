{
  config,
  lib,
  pkgs,
  ...
}: {
  home = {
    packages = [pkgs.k1tty-tools];

    activation.disableK1ttyToolsWelcome = let
      localStorageDir = "${config.xdg.dataHome}/lab.quesada.k1tty-tools/localstorage";
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${lib.getExe' pkgs.coreutils "mkdir"} --parents ${localStorageDir}

        # mark the welcome screen as already seen
        run ${lib.getExe pkgs.sqlite} -cmd '.timeout 5000' ${localStorageDir}/tauri_localhost_0.localstorage \
          "CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB NOT NULL ON CONFLICT FAIL);" \
          "INSERT INTO ItemTable (key, value) VALUES ('k1tty_welcome_v2_seen', X'3100');" # webkit keeps localStorage values as utf-16le blobs
      '';
  };
}
