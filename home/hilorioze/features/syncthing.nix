{config, ...}: {
  imports = [../../common/features/syncthing.nix];

  sops.secrets = {
    "apps/syncthing/certificate" = {};
    "apps/syncthing/private-key" = {};
  };

  services.syncthing = {
    cert = config.sops.secrets."apps/syncthing/certificate".path;
    key = config.sops.secrets."apps/syncthing/private-key".path;

    settings.devices = {
      # keep-sorted start
      hilonix.id = "GFGZO74-4OYK3ER-NTZYIJN-OLC6GYO-2EVMICU-HKZPQES-SFZMO7A-YDFS6AZ";
      lelonix.id = "JQI5YOS-SSATHW7-2474YVF-JHB32UO-53NLVN2-HCXT7S5-74TI6MT-6HCD7QC";
      philone.id = "D264D7E-5CADFYJ-AIUPI6B-MEGIBM2-DATOOE6-77X7ZRK-VIHOSQW-5DBILQB";
      # keep-sorted end
    };
  };
}
