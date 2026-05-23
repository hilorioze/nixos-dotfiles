{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/zsh.nix];

  home.file."${config.programs.zsh.dotDir}/.p10k.zsh".source = ./.p10k.zsh;

  programs.zsh = {
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        if [[ -r "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "${config.xdg.cacheHome}/p10k-instant-prompt-''${(%):-%n}.zsh"
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

      plugins = [
        # keep-sorted start
        "git"
        "sudo"
        # keep-sorted end
      ];
    };
  };
}
