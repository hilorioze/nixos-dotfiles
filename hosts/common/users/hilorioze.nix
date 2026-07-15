{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  sops.secrets."users/hilorioze/hashed-password" = {
    neededForUsers = true;

    sopsFile = lib.mkDefault ../secrets.yaml;
  };

  users.users.hilorioze = {
    uid = 1000;
    isNormalUser = true;

    shell = pkgs.zsh;

    hashedPasswordFile = config.sops.secrets."users/hilorioze/hashed-password".path;
    openssh.authorizedKeys.keys = [
      # keep-sorted start
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgdezqxraUd2gGiPbRygTu8LOgiDAIRrUCe61eAO0fV openpgp:0x6B478424"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbfxu8CyP26944VLHYf6tF/aicquTEO0pJ18puivZ1d openpgp:0xE82274DB"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL+PP6MKrJ6i4aoUhBAQr4sx3ituSLQnlbfO4+nT99G6 openpgp:0x04FB7E2B"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLmFD0F8wiummNyIlj9fHy52JlwMHYISo+GroWSC2tY openpgp:0xF9C7737F"
      # keep-sorted end
    ];

    extraGroups = ["wheel"];
  };

  home-manager.users.hilorioze.imports = [../../../home/hilorioze];
}
