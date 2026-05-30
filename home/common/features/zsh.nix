{config, ...}: {
  programs.zsh = {
    enable = true;

    # Defaults to `~/.config/zsh` since 26.05 if `xdg.enable = true;`
    # https://nix-community.github.io/home-manager/release-notes.xhtml#sec-release-26.05-state-version-changes
    dotDir = "${config.xdg.configHome}/zsh";
  };
}
