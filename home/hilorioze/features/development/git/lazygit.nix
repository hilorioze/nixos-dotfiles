{
  programs.lazygit = {
    enable = true;

    settings = {
      git = {
        autoFetch = false; # avoid automatic ssh fetches prompting for fido2 pin and touch every minute

        ignoreWhitespaceInDiffView = true;

        overrideGpg = true; # allow rewording non-HEAD commits with GPG signing enabled
      };

      gui.showFileTree = false; # list files flat by default instead of as a tree
    };
  };
}
