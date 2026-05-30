{
  imports = [../../common/features/silent-sddm.nix];

  programs.silentSDDM = {
    theme = "catppuccin-macchiato";

    settings."LoginScreen.VirtualKeyboard".start-hidden = false;
  };
}
