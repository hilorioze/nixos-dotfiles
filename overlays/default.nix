{inputs}: {
  # keep-sorted start
  cstrike-mod = inputs.cstrike-mod.overlays.default;
  firefox-addons = inputs.firefox-addons.overlays.default;
  freesmlauncher = _final: prev: inputs.freesmlauncher.packages.${prev.stdenv.hostPlatform.system} or {}; # overlay uses `prev.callPackage`, rebuilding with our `pkgs` and breaking binary cache
  mcp-nixos = inputs.mcp-nixos.overlays.default;
  niks3 = _final: prev: inputs.niks3.packages.${prev.stdenv.hostPlatform.system} or {}; # no upstream overlay; keep cli and server on the same revision to avoid api mismatches
  nix-alien = inputs.nix-alien.overlays.default;
  nix-gaming = _final: prev: inputs.nix-gaming.packages.${prev.stdenv.hostPlatform.system} or {}; # `easyOverlay`'s `mkForce` overrides `pkgs`, rebuilding with our `pkgs` and breaking binary cache
  nix-software-center = inputs.nix-software-center.overlays.default;
  nixos-conf-editor = inputs.nixos-conf-editor.overlays.default;
  # keep-sorted end

  packages = final: _prev: import ../packages {pkgs = final;};

  # keep-sorted start
  linux-bzimage-fix = import ./linux-bzimage-fix;
  plasma-pa-volume-step-snap = import ./plasma-pa-volume-step-snap;
  plasma-workspace-media-keys-no-repeat = import ./plasma-workspace-media-keys-no-repeat;
  spectacle-copy-save = import ./spectacle-copy-save;
  spectacle-ocr-clipboard-fix = import ./spectacle-ocr-clipboard-fix;
  spectacle-ocr-save = import ./spectacle-ocr-save;
  spectacle-region-select-all = import ./spectacle-region-select-all;
  trayscale-operator-no-warning = import ./trayscale-operator-no-warning;
  # keep-sorted end
}
