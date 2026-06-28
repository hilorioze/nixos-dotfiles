{lib, ...}: {
  services.postgresql = {
    enable = true;

    authRules = lib.mkBefore ["local all postgres peer map=postgres"];
  };
}
