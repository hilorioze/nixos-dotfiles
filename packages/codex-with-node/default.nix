{
  # keep-sorted start
  lib,
  makeWrapper,
  nodejs,
  symlinkJoin,
  unstablePkgs,
  # keep-sorted end
}: let
  inherit (unstablePkgs) codex;
in
  symlinkJoin {
    name = "codex-with-node";

    inherit (codex) version;

    paths = [codex];

    nativeBuildInputs = [makeWrapper];

    postBuild = ''
      wrapProgram $out/bin/${codex.meta.mainProgram} \
        --prefix PATH : ${lib.makeBinPath [nodejs]}
    '';

    inherit (codex) meta;
  }
