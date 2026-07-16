{
  programs.plasma.configFile.kwalletrc = {
    KSecretD.Enabled = false; # proxy the `kwallet` api to `keepassxc`'s secret service

    Wallet = {
      "Use One Wallet" = true; # use one collection for local and network credentials

      "Default Wallet" = "Passwords"; # route `kwallet` credentials to `keepassxc`'s `Passwords` collection (the currently opened database itself, not its exposed group)
    };

    "org.freedesktop.secrets".apiEnabled = false; # prevent `ksecretd` from competing with `keepassxc` for `org.freedesktop.secrets`
  };
}
