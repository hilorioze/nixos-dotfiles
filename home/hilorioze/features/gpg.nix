{
  programs.gpg = {
    enable = true;

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
