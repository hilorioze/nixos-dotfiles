_final: prev: {
  podman = prev.podman.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [./healthcheck-ignore-result.patch];
  });
}
