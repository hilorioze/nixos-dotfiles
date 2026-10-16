{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/nix.nix];

  sops = {
    secrets."credentials/attic/servers/rayttage/token" = {};

    templates."apps/nix/netrc".content = "machine attic.rayttage.net password ${config.sops.placeholder."credentials/attic/servers/rayttage/token"}";
  };

  nix.extraOptions = lib.mkAfter ''
    netrc-file = ${config.sops.templates."apps/nix/netrc".path}
  '';
}
