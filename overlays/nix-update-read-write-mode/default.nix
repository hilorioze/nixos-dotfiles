_final: prev: {
  nix-update = prev.nix-update.overrideAttrs (previousAttrs: {
    postPatch =
      (previousAttrs.postPatch or "")
      + ''
        substituteInPlace nix_update/eval.py \
          --replace-fail '"--eval",' '"--eval", "--read-write-mode",'
      '';
  });
}
