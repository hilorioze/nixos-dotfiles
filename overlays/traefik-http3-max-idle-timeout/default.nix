_final: prev: {
  traefik = prev.traefik.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [./http3-max-idle-timeout.patch];
  });
}
