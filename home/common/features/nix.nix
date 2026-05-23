{config, ...}: {
  sops = {
    secrets."credentials/github/token" = {};

    templates."config/nix/access-tokens".content = ''
      access-tokens = github.com=${config.sops.placeholder."credentials/github/token"}
    '';
  };

  nix.extraOptions = ''
    !include ${config.sops.templates."config/nix/access-tokens".path}
  '';
}
