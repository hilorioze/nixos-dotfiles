{
  imports = [../../common/features/wakatime.nix];

  sops.secrets."apps/wakatime/api-key".sopsFile = ../secrets.yaml;
}
