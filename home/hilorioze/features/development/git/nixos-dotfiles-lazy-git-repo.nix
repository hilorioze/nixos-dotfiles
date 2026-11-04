{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  home.activation.nixosDotfilesLazyGitRepoInit = ''
    repo_dir=${config.home.homeDirectory}/projects/nixos-dotfiles

    if [[ ! -d $repo_dir/.git ]]; then
      ${lib.getExe pkgs.git} init $repo_dir

      ${lib.getExe pkgs.git} -C $repo_dir remote add origin git@github.com:hilorioze/nixos-dotfiles.git
    fi
  '';
}
