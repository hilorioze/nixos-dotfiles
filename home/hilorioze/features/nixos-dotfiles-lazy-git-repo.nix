{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.activation.nixosDotfilesLazyGitRepoInit = ''
    if [ ! -d ${config.home.homeDirectory}/projects/nixos-dotfiles/.git ]; then
      ${lib.getExe pkgs.git} init ${config.home.homeDirectory}/projects/nixos-dotfiles

      ${lib.getExe pkgs.git} -C ${config.home.homeDirectory}/projects/nixos-dotfiles remote add origin git@github.com:hilorioze/nixos-dotfiles.git
    fi
  '';
}
