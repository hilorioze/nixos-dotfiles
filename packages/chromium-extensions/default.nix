{
  # keep-sorted start
  fetchurl,
  lib,
  name,
  ungoogled-chromium,
  writers,
  # keep-sorted end
}: let
  extension = (lib.importJSON ./sources.json).${name};

  updateExtension = writers.writePython3 "update-chromium-extension" {
    flakeIgnore = (import ../../shared.nix).ignoredFlake8Rules;
  } (builtins.readFile ./update-chromium-extension.py);
in
  # the download url carries an opaque store token, so the update script records it next to the version and hash
  fetchurl {
    pname = name;

    inherit (extension) version;

    inherit (extension) url;

    inherit (extension) hash;

    passthru = {
      inherit (extension) id;

      # ask the web store for the release compatible with the browser that installs it
      updateScript = [updateExtension name ungoogled-chromium.version];
    };
  }
