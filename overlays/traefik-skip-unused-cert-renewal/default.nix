_final: prev: {
  traefik = prev.traefik.overrideAttrs (oldAttrs: {
    # traefik keeps renewing every certificate in `acme.json`, also the ones no router uses anymore; backport of https://github.com/traefik/traefik/pull/14259
    patches =
      (oldAttrs.patches or [])
      ++ [./skip-unused-cert-renewal.patch];
  });
}
