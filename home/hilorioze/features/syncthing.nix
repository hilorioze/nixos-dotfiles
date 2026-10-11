{config, ...}: {
  sops.secrets."apps/syncthing/private-key" = {};

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
        hilonix.id = "GFGZO74-4OYK3ER-NTZYIJN-OLC6GYO-2EVMICU-HKZPQES-SFZMO7A-YDFS6AZ";
        lelonix.id = "JQI5YOS-SSATHW7-2474YVF-JHB32UO-53NLVN2-HCXT7S5-74TI6MT-6HCD7QC";
        philone.id = "VHDWD3D-HFPWFYH-BZZAWGB-F62N6XS-QFND3NG-XZKLAX2-MOEX46X-CUXXIQX";
        zikkkix.id = "WWNU35D-2QFBCXD-OXBY4EF-6SZ4ZNK-F5WD4N4-724I5IV-RDPRWL3-QO7VUQU";
        # keep-sorted end
      };

      folders.sync = {
        path = "${config.home.homeDirectory}/Sync";

        devices = ["philone"];
      };
    };
  };
}
