{
  programs.gpg = {
    enable = true;

    publicKeys = [
      {
        source = ./openpgp-cert.asc;

        trust = "ultimate";
      }
    ];
  };
}
