_final: prev: {
  xdg-desktop-portal = prev.xdg-desktop-portal.overrideAttrs (oldAttrs: {
    # `bwrap` cannot configure loopback inside the Nix build sandbox
    preCheck =
      (oldAttrs.preCheck or "")
      + ''
        export XDP_VALIDATE_ICON_INSECURE=1
        export XDP_VALIDATE_SOUND_INSECURE=1
      '';
  });
}
