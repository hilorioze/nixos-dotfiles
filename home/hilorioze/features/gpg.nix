{pkgs, ...}: {
  programs.gpg = {
    enable = true;

    package = pkgs.gnupg-pcsc-shared-reselect-fix;

    publicKeys = [
      {
        source = ./openpgp-cert.asc;

        trust = "ultimate";
      }
    ];

    scdaemonSettings = {
      disable-ccid = true;
      pcsc-shared = true;
    };
  };
}
