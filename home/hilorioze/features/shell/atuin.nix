{config, ...}: {
  sops.secrets."apps/atuin/encryption-key" = {};

  programs.atuin = {
    enable = true;

    daemon.enable = true; # sync independently of active shells

    settings = {
      key_path = config.sops.secrets."apps/atuin/encryption-key".path;

      daemon.sync_frequency = 10; # keep cross-host history responsive; 5 minutes is too long

      enter_accept = true; # enter immediately executes the selected command from history rather than returning it for editing

      ai.enabled = false;
    };
  };
}
