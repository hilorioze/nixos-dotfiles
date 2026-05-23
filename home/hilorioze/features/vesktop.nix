{
  imports = [../../common/features/vesktop.nix];

  programs.vesktop.vencord.settings.plugins = {
    # keep-sorted start newline_separated=yes
    FakeNitro.enabled = true;

    MessageLogger.enabled = true;
    # keep-sorted end
  };
}
