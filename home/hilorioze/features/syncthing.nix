{config, ...}: {
  sops.secrets = {
    # keep-sorted start
    "apps/syncthing/folders/sync/encryption-password" = {};
    "apps/syncthing/private-key" = {};
    # keep-sorted end
  };

  services.syncthing = {
    enable = true;

    key = config.sops.secrets."apps/syncthing/private-key".path;

    settings = {
      options = {
        urAccepted = -1; # disable usage reporting

        crashReportingEnabled = false;
      };

      devices = {
        # keep-sorted start
        de0.id = "OEB2SDB-6WQEXX5-D5FBIJY-GBFA7GN-EQ7K73O-OWXUKZC-5U6ZDEU-TZQCVA4";
        hilonix.id = "GFGZO74-4OYK3ER-NTZYIJN-OLC6GYO-2EVMICU-HKZPQES-SFZMO7A-YDFS6AZ";
        lelonix.id = "JQI5YOS-SSATHW7-2474YVF-JHB32UO-53NLVN2-HCXT7S5-74TI6MT-6HCD7QC";
        philone.id = "VHDWD3D-HFPWFYH-BZZAWGB-F62N6XS-QFND3NG-XZKLAX2-MOEX46X-CUXXIQX";
        zikkkix.id = "WWNU35D-2QFBCXD-OXBY4EF-6SZ4ZNK-F5WD4N4-724I5IV-RDPRWL3-QO7VUQU";
        # keep-sorted end
      };

      folders.sync = {
        path = "${config.home.homeDirectory}/Sync";

        # deletions and overwrites from other devices propagate right away; keep thinned-out history of the replaced files
        versioning = {
          type = "staggered";

          params.maxAge = toString (365 * 24 * 3600); # 1y in seconds
        };

        devices = [
          "philone"

          # always-on relay between devices; only holds the encrypted data
          {
            name = "de0";

            encryptionPasswordFile = config.sops.secrets."apps/syncthing/folders/sync/encryption-password".path;
          }
        ];
      };
    };
  };
}
