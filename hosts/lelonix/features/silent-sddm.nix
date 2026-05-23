{
  imports = [
    # keep-sorted start
    ../../common/features/silent-sddm.nix
    # keep-sorted end
  ];

  programs.silentSDDM = {
    theme = "catppuccin-macchiato";

    settings."LoginScreen.VirtualKeyboard".start-hidden = false;
  };
}
