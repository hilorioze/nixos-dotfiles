{lib}: let
  # keep-sorted start
  attrsets = import ./attrsets.nix {inherit lib;};
  options = import ./options.nix {inherit lib;};
  # keep-sorted end
in {
  # keep-sorted start
  inherit attrsets;
  inherit options;
  # keep-sorted end
}
