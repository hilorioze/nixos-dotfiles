{
  programs.lazygit = {
    enable = true;

    settings = {
      git.autoFetch = false; # avoid automatic SSH fetches prompting for FIDO2 PIN and touch every minute

      gui.showFileTree = false; # list files flat by default instead of as a tree
    };
  };
}
