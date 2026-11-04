{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.file."${config.programs.zsh.dotDir}/.p10k.zsh".source = ./.p10k.zsh;

  programs.zsh = {
    enable = true;

    # defaults to `~/.config/zsh` since 26.05 if `xdg.enable = true;`
    # https://nix-community.github.io/home-manager/release-notes.xhtml#sec-release-26.05-state-version-changes
    dotDir = "${config.xdg.configHome}/zsh";

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        if [[ -r ${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh ]]; then
          source ${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh
        fi
      '')

      ''
        [[ ! -f ${config.programs.zsh.dotDir}/.p10k.zsh ]] || source ${config.programs.zsh.dotDir}/.p10k.zsh
      ''
    ];

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    plugins = [
      {
        name = "powerlevel10k";

        src = pkgs.zsh-powerlevel10k;

        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    oh-my-zsh = {
      enable = true;

      plugins = ["sudo"];
    };
  };
}
