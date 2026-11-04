{
  programs.ripgrep = {
    enable = true;

    arguments = [
      # keep-sorted start
      "--glob=!**/.git/**"
      "--hidden"
      "--smart-case"
      # keep-sorted end
    ];
  };
}
