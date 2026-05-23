{
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 34560000;
    maxCacheTtl = 34560000;
    defaultCacheTtlSsh = 34560000;
    maxCacheTtlSsh = 34560000;
  };
}
