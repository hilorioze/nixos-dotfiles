{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs = {
    thunderbird = {
      enable = true;

      profiles.default = {
        isDefault = true; # lol, why is it not like in firefox?: "true if profile ID is 0"

        withExternalGnupg = true; # allow `thunderbird` to use system `gpg-agent` via `gpgme`

        # explicit account display order instead of `accounts.email.accounts` default alphabetical order; also include the manually configured mailbox's id
        accountsOrder = [
          "me@hilorioze.com"
          "hilorioze@gmail.com"
          "root@hilorioze.com"
          "account2" # manually configured mailbox's id
          # `home-manager` already automatically appends "Local Folders", which `thunderbird` assigns `account1`
        ];

        settings = {
          # omit `User-Agent` from outgoing messages because it might be stripped in transit and invalidate the `openpgp` signature
          "mailnews.headers.sendUserAgent" = false;

          # suppress `thunderbird`'s "Know your rights" first-run notification
          "mail.rights.override" = true;

          # disable telemetry data submission; this also prevents the first-run privacy policy tab, making `dataSubmissionPolicyBypassNotification` unnecessary
          "datareporting.policy.dataSubmissionEnabled" = false;
        };
      };
    };

    plasma.configFile.emaildefaults.PROFILE_Default.EmailClient = "thunderbird.desktop"; # resolve plasma's `preferred://mailer` to thunderbird
  };

  home.activation = let
    thunderbirdProfileDir = "${config.home.homeDirectory}/.thunderbird/${config.programs.thunderbird.profiles.default.name}";

    # keep the fingerprint lowercased to match `thunderbird`'s normalized value in the `openpgp` acceptance database; `gpg` accepts it as well
    gpgPrimaryKeyFingerprint = "96715efaa4fb67f96d3b335258da93fdd2d02b8d";
  in {
    # merge the public key into `thunderbird`'s `pubring.gpg` because it requires the public key in its `rnp` keyring even when signing with external `gpg` via `gpgme`; also preserve other public keys already imported there
    exportGpgPublicKeyToThunderbird = lib.hm.dag.entryAfter ["writeBoundary" "importGpgKeys"] ''
      run ${lib.getExe' pkgs.coreutils "mkdir"} --parents ${thunderbirdProfileDir}

      ${lib.getExe pkgs.gnupg} --export ${gpgPrimaryKeyFingerprint} | run ${lib.getExe' pkgs.rnp "rnpkeys"} \
        --homedir ${thunderbirdProfileDir} \
        --import-keys -
    '';

    # mark own public key as verified in `thunderbird`'s separate `openpgp` acceptance database because `gpg` ownertrust is not imported by `gpgme`
    # create the acceptance schema as well, so accepting this key works for both fresh and existing profiles
    # `personal` requires secret material in `rnp`; this profile keeps it in external `gpg`, so accept the exported public key as `verified`
    acceptOwnGpgPublicKeyInThunderbird = let
      thunderbirdOpenPgpDatabase = "${thunderbirdProfileDir}/openpgp.sqlite";

      gpgPrimaryKeyEmail = "me@hilorioze.com";
    in
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        run ${lib.getExe' pkgs.coreutils "mkdir"} --parents ${thunderbirdProfileDir}

        run ${lib.getExe pkgs.sqlite} ${thunderbirdOpenPgpDatabase} \
          "PRAGMA busy_timeout = 5000;" \
          "BEGIN;" \
          "CREATE TABLE IF NOT EXISTS acceptance_email (fpr TEXT NOT NULL, email TEXT NOT NULL, UNIQUE(fpr, email));" \
          "CREATE TABLE IF NOT EXISTS acceptance_decision (fpr TEXT NOT NULL, decision TEXT NOT NULL, UNIQUE(fpr));" \
          "CREATE UNIQUE INDEX IF NOT EXISTS acceptance_email_i1 ON acceptance_email(fpr, email);" \
          "CREATE UNIQUE INDEX IF NOT EXISTS acceptance__decision_i1 ON acceptance_decision(fpr);" \
          "DELETE FROM acceptance_email WHERE fpr = '${gpgPrimaryKeyFingerprint}';" \
          "INSERT OR REPLACE INTO acceptance_decision (fpr, decision) VALUES ('${gpgPrimaryKeyFingerprint}', 'verified');" \
          "INSERT OR IGNORE INTO acceptance_email (fpr, email) VALUES ('${gpgPrimaryKeyFingerprint}', '${gpgPrimaryKeyEmail}');" \
          "COMMIT;"
      '';
  };

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/rss+xml" = "thunderbird.desktop";
    "message/rfc822" = "thunderbird.desktop";
    "text/calendar" = "thunderbird.desktop";
    "x-scheme-handler/feed" = "thunderbird.desktop";
    "x-scheme-handler/mailto" = "thunderbird.desktop";
    "x-scheme-handler/mid" = "thunderbird.desktop";
    "x-scheme-handler/net.thunderbird" = "thunderbird.desktop";
    "x-scheme-handler/news" = "thunderbird.desktop";
    "x-scheme-handler/nntp" = "thunderbird.desktop";
    "x-scheme-handler/snews" = "thunderbird.desktop";
    "x-scheme-handler/webcal" = "thunderbird.desktop";
    "x-scheme-handler/webcals" = "thunderbird.desktop";
    # keep-sorted end
  };
}
