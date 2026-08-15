{pkgs, ...}: {
  packages = with pkgs; [
    # keep-sorted start
    age # ships `age-plugin-tag`; required to encrypt to age1tag1 recipients
    deploy-rs
    sops
    # keep-sorted end
  ];

  languages = {
    # keep-sorted start block=yes newline_separated=yes
    lua.enable = true;

    nix = {
      enable = true;

      lsp.package = pkgs.nil;
    };
    # keep-sorted end
  };

  treefmt = {
    enable = true;

    config.programs = {
      # keep-sorted start block=yes newline_separated=yes
      alejandra = {
        enable = true;

        priority = 100;
      };

      deadnix.enable = true;

      keep-sorted.enable = true;

      statix.enable = true;
      # keep-sorted end
    };
  };

  git-hooks.hooks = let
    ignoredShellcheckRules = [
      # keep-sorted start
      "SC2016" # expressions in single quotes; intentional, referenced have no shell expansion
      "SC2086" # unquoted variables; referenced are safe
      "SC2162" # `read` without `-r`; intentional too, paths and stuff don't have backslashes
      "SC2231" # unquoted variable in `for` loop glob; see `SC2086`
      # keep-sorted end
    ];
  in {
    # keep-sorted start block=yes newline_separated=yes
    actionlint = {
      enable = true;

      args =
        (map (code: "-ignore=${code}") ignoredShellcheckRules)
        ++ [
          ''-ignore=property \"collect-targets\" is not defined'' # anchor references `needs.collect-targets` itself; should and only exists in downstream jobs
        ];
    };

    check-merge-conflicts = {
      enable = true;

      fail_fast = true; # abort immediately so treefmt never runs on conflicted files
    };

    # use `.editorconfig` as the single source of truth for generic file normalization
    eclint = {
      enable = true;

      types = ["text"];

      # `eclint` only processes the first positional path, so let it discover tracked files itself
      pass_filenames = false;

      # `eclint` does not support `.editorconfig`'s `unset` value
      excludes = ["\\.diff$" "\\.patch$"];

      args = ["-exclude" "{*.{diff,patch},**/*.{diff,patch}}"];

      settings.fix = true;
    };

    flake-checker.enable = true;

    pre-commit-hook-ensure-sops.enable = true;

    shellcheck = {
      enable = true;

      args = map (code: "--exclude=${code}") ignoredShellcheckRules;

      # produces false positives on zsh
      excludes = ["\\.zsh$"];
    };

    treefmt = {
      enable = true;

      after = ["check-merge-conflicts"];
    };
    # keep-sorted end
  };

  devcontainer = {
    enable = true;

    settings = {
      # cache `/nix` between rebuilds
      mounts = ["source=devcontainer-nix,target=/nix,type=volume"];

      onCreateCommand = ''sudo sh -c 'printf "accept-flake-config = true\n" >> /etc/nix/nix.conf' '';

      customizations.vscode.extensions = [
        # keep-sorted start
        "EditorConfig.EditorConfig"
        "jnoortheen.nix-ide"
        "mkhl.direnv"
        # keep-sorted end
      ];
    };
  };

  # ensure generated files (like `.devcontainer/devcontainer.json`) exist before `treefmt` runs to prevent race conditions
  tasks."devenv:treefmt:run".after = ["devenv:files"];
}
