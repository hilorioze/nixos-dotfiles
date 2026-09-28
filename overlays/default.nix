{inputs}: [
  # keep-sorted start by_regex=inputs\.([\w-]+)
  inputs.cstrike-mod.overlays.default
  inputs.firefox-addons.overlays.default
  (_final: prev: inputs.freesmlauncher.packages.${prev.stdenv.hostPlatform.system} or {}) # overlay uses `prev.callPackage`, rebuilding with our `pkgs` and breaking binary cache
  (_final: prev: inputs.niks3.packages.${prev.stdenv.hostPlatform.system} or {}) # no upstream overlay; keep cli and server on the same revision to avoid api mismatches
  inputs.nix-alien.overlays.default
  (_final: prev: inputs.nix-gaming.packages.${prev.stdenv.hostPlatform.system} or {}) # `easyOverlay`'s `mkForce` overrides `pkgs`, rebuilding with our `pkgs` and breaking binary cache
  inputs.nix-software-center.overlays.default
  inputs.nix-vscode-extensions.overlays.default
  inputs.nixos-conf-editor.overlays.default
  inputs.steam-voicechat-fix.overlays.default
  # keep-sorted end

  (_final: prev: {
    unstablePkgs = import inputs.nixpkgs-unstable {
      localSystem = prev.stdenv.hostPlatform.system;

      inherit (prev) config;
    };
  })

  (import ./nix-update-unstable) # must precede the local overlays that extend it

  # keep-sorted start
  (import ./bambu-studio-cuda-fix)
  (import ./desomnia-dbus-completion-fix)
  (import ./gnupg-pcsc-shared-reselect-fix)
  (import ./lazyvim-wakatime inputs.lazyvim-nix.overlays.default)
  (import ./looking-glass-client-idd)
  (import ./nix-monitored-notification-utf8-fix)
  (import ./nix-update-read-write-mode)
  (import ./nix-update-script-flake-mode)
  (import ./nix-update-skip-package-environment)
  (import ./nix-update-skip-update)
  (import ./nvidia-linux-7-2-fix)
  (import ./plasma-pa-volume-step-snap)
  (import ./plasma-workspace-media-keys-no-repeat)
  (import ./podman-healthcheck-ignore-result)
  (import ./spectacle-copy-save)
  (import ./spectacle-ocr-clipboard-fix)
  (import ./spectacle-ocr-save)
  (import ./spectacle-region-select-all)
  (import ./trayscale-operator-no-warning)
  (import ./wivrn-26-9)
  (import ./write-shell-application-shellcheck-exclusions)
  (import ./xdg-desktop-portal-sandbox-tests-fix)
  # keep-sorted end
]
