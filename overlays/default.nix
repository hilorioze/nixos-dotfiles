{inputs}: [
  (final: _prev: import ../packages {pkgs = final;}) # apply local packages first so later overlays can override them

  # keep-sorted start by_regex=inputs\.([\w-]+)
  inputs.cstrike-mod.overlays.default
  inputs.firefox-addons.overlays.default
  inputs.freesmlauncher.overlays.default
  inputs.mud.overlays.default
  inputs.nix-alien.overlays.default
  inputs.nix-vscode-extensions.overlays.default
  inputs.steam-voicechat-fix.overlays.default
  # keep-sorted end

  # must precede the local overlays that extend it
  (_final: prev: {
    unstablePkgs = import inputs.nixpkgs-unstable {
      localSystem = prev.stdenv.hostPlatform.system;

      inherit (prev) config;
    };
  })

  # keep-sorted start
  (import ./claude-code-alsa-rpath)
  (import ./cliproxyapi-antigravity-web-search)
  (import ./cliproxyapi-response-model-prefix)
  (import ./devenv-unstable)
  (import ./gnupg-pcsc-shared-reselect-fix)
  (import ./gpu-screen-recorder-ui-unused-gpu-fix)
  (import ./konsole-wayland-tab-dnd-fix)
  (import ./lazyvim-wakatime inputs.lazyvim-nix.overlays.default)
  (import ./looking-glass-client-idd)
  (import ./nix-update-read-write-mode)
  (import ./nix-update-script-flake-mode)
  (import ./nix-update-skip-package-environment)
  (import ./nix-update-skip-update)
  (import ./plasma-pa-volume-step-snap)
  (import ./plasma-workspace-media-keys-no-repeat)
  (import ./playwright-mcp-patchright)
  (import ./podman-healthcheck-ignore-result)
  (import ./silent-sddm-double-scale-fix inputs.silent-sddm)
  (import ./spectacle-copy-save)
  (import ./spectacle-ocr-clipboard-fix)
  (import ./spectacle-ocr-save)
  (import ./spectacle-region-select-all)
  (import ./trayscale-operator-no-warning)
  (import ./wivrn-26-9)
  (import ./xdg-desktop-portal-sandbox-tests-fix)
  # keep-sorted end
]
