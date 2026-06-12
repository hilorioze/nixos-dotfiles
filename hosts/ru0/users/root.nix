{lib, ...}: {
  imports = [../../common/users/root.nix];

  security.pam.services.sshd.unixAuth = lib.mkForce true; # required since we enable `PasswordAuthentication` in `extraConfig`. ref: https://github.com/NixOS/nixpkgs/blob/d640c73373afee4c2a0ba24d649803d491762210/nixos/modules/services/networking/ssh/sshd.nix#L799

  services.openssh = {
    settings.PermitRootLogin = "yes";

    extraConfig = ''
      Match User root
        PasswordAuthentication yes
    '';
  };
}
