hermes-agent: final: _prev: {
  # the recipe builds from the tree it sits in, so `.override` can't patch it; call it from the patched tree instead
  hermes-agent = let
    upstreamPkgs = hermes-agent.inputs.nixpkgs.legacyPackages.${final.stdenv.hostPlatform.system}; # `nixpkgs-unstable` without our overlays

    src = final.applyPatches {
      name = "hermes-agent-source";

      src = hermes-agent;

      patches = final.hermesAgentPatches or []; # each `hermes-agent-*` overlay adds its patch here
    };
  in
    upstreamPkgs.callPackage "${src}/nix/hermes-agent.nix" {
      inherit (hermes-agent.inputs) pyproject-build-systems pyproject-nix uv2nix;
      inherit (hermes-agent) lastModified rev;

      # the backport upstream adds to patchelf only applies to 0.19.2, and the 0.15.2 nixpkgs went back to doesn't have the bug; drop once https://github.com/NousResearch/hermes-agent/pull/152542 lands
      pmPackages = final.lib.filterAttrs (_: final.lib.isDerivation) (upstreamPkgs.callPackage "${src}/nix/pm-packages.nix" {
        patchelf = upstreamPkgs.patchelf // {overrideAttrs = _: upstreamPkgs.patchelf;};
      });
    };
}
