{
  # keep-sorted start
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };
}
