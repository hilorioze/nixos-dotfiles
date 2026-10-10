{
  # keep-sorted start
  lib,
  makeWrapper,
  nodejs,
  symlinkJoin,
  unstablePkgs,
  # keep-sorted end
}: let
  inherit (unstablePkgs) claude-code;
in
  symlinkJoin {
    name = "claude-code-with-node";

    inherit (claude-code) version;

    paths = [claude-code];

    nativeBuildInputs = [makeWrapper];

    postBuild = ''
      wrapProgram $out/bin/${claude-code.meta.mainProgram} \
        --prefix PATH : ${lib.makeBinPath [nodejs]}
    '';

    passthru.skipUpdate = true; # version follows the 'nixpkgs-unstable' input

    inherit (claude-code) meta;
  }
