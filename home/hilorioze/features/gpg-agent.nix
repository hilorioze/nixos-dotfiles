{pkgs, ...}: {
  services.gpg-agent = {
    enable = true;

    pinentry.package = pkgs.pinentry-qt;

    defaultCacheTtl = 34560000;
    maxCacheTtl = 34560000;
  };
}
