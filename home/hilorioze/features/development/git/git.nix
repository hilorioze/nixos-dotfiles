{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  programs = {
    zsh.oh-my-zsh.plugins = ["git"];

    git = {
      enable = true;

      settings = {
        user = {
          name = "hilorioze";
          email = "hilorioze@hilorioze.com";
        };

        init.defaultBranch = "main";

        pull.rebase = true;

        alias = {
          aa = "add --all";
          cm = "commit --message";
          f = "fetch --all";
          ps = "push";
          pf = "push --force-with-lease"; # safe force push, checks remote state
          pl = "pull";
          s = "status --short --branch";
          l = "log --oneline --graph --decorate --all";
          st = "stash";
          stl = "stash list";
          stp = "stash pop";
        };
      };
    };
  };

  home.shellAliases.g = lib.getExe config.programs.git.package;
}
