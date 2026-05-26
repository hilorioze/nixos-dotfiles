{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets = {
    # keep-sorted start
    "credentials/gpg/subkeys/auth/private-key" = {};
    "credentials/gpg/subkeys/encrypt/private-key" = {};
    "credentials/gpg/subkeys/sign/private-key" = {};
    # keep-sorted end
  };

  home.activation.importGpgSubkeys = let
    gpgPrimaryKeyFingerprint = "96715EFAA4FB67F96D3B335258DA93FDD2D02B8D";

    gpgSubkeySecretPaths = [
      # keep-sorted start
      config.sops.secrets."credentials/gpg/subkeys/auth/private-key".path
      config.sops.secrets."credentials/gpg/subkeys/encrypt/private-key".path
      config.sops.secrets."credentials/gpg/subkeys/sign/private-key".path
      # keep-sorted end
    ];

    gpgOwnerTrustFile = pkgs.writeText "gpg-ownertrust-hilorioze.txt" ''
      ${gpgPrimaryKeyFingerprint}:6:
    '';
  in
    lib.hm.dag.entryAfter ["sops-nix"] ''
      export GNUPGHOME=${lib.escapeShellArg config.programs.gpg.homedir}

      run ${lib.getExe' pkgs.coreutils "install"} -d -m 0700 "$GNUPGHOME"

      ${lib.concatMapStringsSep "\n" (gpgSubkeySecretPath: ''
          if [[ -s ${lib.escapeShellArg gpgSubkeySecretPath} ]]; then
            run ${lib.getExe pkgs.gnupg} --batch --import-options restore --import ${lib.escapeShellArg gpgSubkeySecretPath}
          fi
        '')
        gpgSubkeySecretPaths}

      run ${lib.getExe pkgs.gnupg} --import-ownertrust ${lib.escapeShellArg gpgOwnerTrustFile}
    '';
}
