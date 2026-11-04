{
  security.sudo = {
    enable = true;

    extraConfig = ''
      Defaults timestamp_timeout=-1
      Defaults passwd_timeout=0
      Defaults pwfeedback
    '';
  };
}
