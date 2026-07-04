{
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        email = "me@hilorioze.com";
        name = "hilorioze";
      };

      signing = {
        behavior = "own";

        backend = "gpg";
      };

      remotes.origin.auto-track-bookmarks = "main";
    };
  };
}
