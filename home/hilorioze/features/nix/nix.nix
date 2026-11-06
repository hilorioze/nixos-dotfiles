{config, ...}: {
  sops = {
    secrets = {
      # keep-sorted start
      "credentials/attic/servers/rayttage/token" = {};
      "credentials/github/token" = {};
      # keep-sorted end
    };

    templates = {
      "apps/nix/access-tokens".content = "access-tokens = github.com=${config.sops.placeholder."credentials/github/token"}";

      "apps/nix/netrc".content = "machine attic.rayttage.net password ${config.sops.placeholder."credentials/attic/servers/rayttage/token"}";
    };
  };

  nix.extraOptions = ''
    !include ${config.sops.templates."apps/nix/access-tokens".path}

    netrc-file = ${config.sops.templates."apps/nix/netrc".path}
  '';
}
