{inputs}: [
  (final: _prev: import ../packages {pkgs = final;}) # apply local packages first so later overlays can override them

  # keep-sorted start by_regex=inputs\.([\w-]+)
  inputs.cstrike-mod.overlays.default
  inputs.firefox-addons.overlays.default
  inputs.freesmlauncher.overlays.default
  inputs.hilot.overlays.default
  inputs.mud.overlays.default
  inputs.nix-vscode-extensions.overlays.default
  # keep-sorted end

  # must precede the local overlays that extend it
  (final: _prev: {
    unstablePkgs = import inputs.nixpkgs-unstable {
      localSystem = final.stdenv.hostPlatform.system;

      inherit (final) config;
    };

    unstableSmallPkgs = import inputs.nixpkgs-unstable-small {
      localSystem = final.stdenv.hostPlatform.system;

      inherit (final) config;
    };
  })

  # keep-sorted start
  (import ./chiaki-ng-aia-default-trust-store)
  (import ./claude-code-alsa-rpath)
  (import ./cliproxyapi-antigravity-web-search)
  (import ./cliproxyapi-claude-chat-web-search)
  (import ./cliproxyapi-response-model-prefix)
  (import ./cliproxyapi-system-instruction-as-user)
  (import ./devenv-unstable)
  (import ./gnupg-pcsc-shared-reselect-fix)
  (import ./gpu-screen-recorder-drm-master-fix)
  (import ./gpu-screen-recorder-ui-unused-gpu-fix)
  (import ./hermes-agent inputs.hermes-agent)
  (import ./hermes-agent-cron-monitor-url-in-terminal)
  (import ./hermes-agent-cron-scripts-in-terminal)
  (import ./hermes-agent-image-cache-model-path)
  (import ./hermes-agent-model-switch-configured-key)
  (import ./hermes-agent-openai-native-web-search-chat)
  (import ./hermes-agent-ssh-remote-kill)
  (import ./hermes-agent-sync-back-skip-runtime-cache)
  (import ./konsole-wayland-tab-dnd-fix)
  (import ./looking-glass-client-idd)
  (import ./miniupnpd-delete-range-ownership)
  (import ./niks3-upstream-cache-filter)
  (import ./nix-update-read-write-mode)
  (import ./nix-update-script-flake-mode)
  (import ./nix-update-skip-package-environment)
  (import ./nix-update-skip-update)
  (import ./plasma-pa-volume-step-snap)
  (import ./plasma-workspace-media-keys-no-repeat)
  (import ./playwright-mcp-patchright)
  (import ./podman-healthcheck-ignore-result)
  (import ./pytapo-3-4-31)
  (import ./return-youtube-dislikes-data-collection-no-prompt)
  (import ./silent-sddm-double-scale-fix inputs.silent-sddm)
  (import ./spectacle-copy-save)
  (import ./spectacle-ocr-clipboard-fix)
  (import ./spectacle-ocr-save)
  (import ./spectacle-region-select-all)
  (import ./switch-to-configuration-user-units-after-wrappers)
  (import ./traefik-skip-unused-cert-renewal)
  (import ./trayscale-operator-no-warning)
  (import ./wivrn-26-9)
  (import ./xdg-desktop-portal-sandbox-tests-fix)
  # keep-sorted end
]
