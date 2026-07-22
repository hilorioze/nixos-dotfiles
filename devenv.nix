{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  packages = with pkgs; [
    # keep-sorted start
    age # ships `age-plugin-tag`; required to encrypt to age1tag1 recipients
    deploy-rs
    sops
    # keep-sorted end
  ];

  scripts = {
    # keep-sorted start
    du.exec = "devenv update";
    nbah.exec = "nix eval .#nixosConfigurations --apply builtins.attrNames --json | ${lib.getExe pkgs.jq} -r '.[]' | while IFS= read -r host; do ${lib.getExe config.scripts.nbh.scriptPackage} $host; done";
    nbh.exec = "nix build -L .#nixosConfigurations.$1.config.system.build.toplevel";
    nfc.exec = "nix flake check";
    nfl.exec = "nix flake lock";
    nfu.exec = "nix flake update";
    ua.exec = "${lib.getExe config.scripts.du.scriptPackage} && ${lib.getExe config.scripts.nfu.scriptPackage}";
    # keep-sorted end
  };

  languages = {
    # keep-sorted start
    lua.enable = true;
    nix.enable = true;
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

  git-hooks.hooks = {
    # keep-sorted start block=yes newline_separated=yes
    check-merge-conflicts = {
      enable = true;

      fail_fast = true; # abort immediately so treefmt never runs on conflicted files
    };

    end-of-file-fixer = {
      enable = true;

      excludes = [
        "\\.diff$"
        "\\.patch$"
        "\\.pub$" # we want `readFile ssh_host_ed25519_key.pub` to return the public key without a newline
      ];
    };

    flake-checker.enable = true;

    mixed-line-endings = {
      enable = true;

      # force LF line endings
      args = ["--fix=lf"];

      excludes = ["\\.diff$" "\\.patch$"];
    };

    pre-commit-hook-ensure-sops.enable = true;

    shellcheck = {
      enable = true;

      # produces false positives on zsh
      excludes = ["\\.zsh$"];
    };

    treefmt = {
      enable = true;

      after = ["check-merge-conflicts"];
    };

    trim-trailing-whitespace = {
      enable = true;

      # preserve markdown hard linebreaks (https://github.github.com/gfm/#hard-line-break)
      args = ["--markdown-linebreak-ext=md"];

      excludes = ["\\.diff$" "\\.patch$"];
    };
    # keep-sorted end
  };

  devcontainer = {
    enable = true;

    settings = {
      # cache /nix between rebuilds
      mounts = ["source=devcontainer-nix,target=/nix,type=volume"];

      onCreateCommand = "sudo sh -c 'echo \"accept-flake-config = true\" >> /etc/nix/nix.conf'";

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
