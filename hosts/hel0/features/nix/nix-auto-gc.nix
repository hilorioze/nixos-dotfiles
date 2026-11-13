{lib, ...}: {
  # the 34G disk never has the common 10G free, so every nix command would collect garbage first
  nix.settings = {
    max-free = lib.mkForce (5 * 1024 * 1024 * 1024); # 5G

    min-free = lib.mkForce (2 * 1024 * 1024 * 1024); # 2G
  };
}
