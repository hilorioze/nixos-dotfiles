{config, ...}: {
  sops.secrets."credentials/ssh/fido2/private-key".path = "${config.home.homeDirectory}/.ssh/id_ed25519_sk";

  programs.ssh.settings."*".AddKeysToAgent = "yes";
}
