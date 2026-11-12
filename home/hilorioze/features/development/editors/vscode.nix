{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.vscode = {
    enable = true;

    # stable's recipe still removes the bundled ripgrep from a path 1.144.0 no longer has and fails to build
    package = pkgs.unstablePkgs.vscode.overrideAttrs (oldAttrs: {
      # append nil to `PATH`, so a devenv's own nil comes first
      preFixup =
        oldAttrs.preFixup
        + ''
          gappsWrapperArgs+=(--suffix PATH : ${lib.makeBinPath [pkgs.nil]})
        '';
    });

    mutableExtensionsDir = false;

    profiles.default = {
      enableUpdateCheck = false;

      enableExtensionUpdateCheck = false;

      extensions =
        (with pkgs.vscode-extensions; [
          # keep-sorted start
          charliermarsh.ruff
          davidanson.vscode-markdownlint
          eamodio.gitlens
          editorconfig.editorconfig
          github.codespaces
          github.vscode-github-actions
          github.vscode-pull-request-github
          jnoortheen.nix-ide
          mkhl.direnv
          ms-python.debugpy
          ms-python.python
          ms-python.vscode-pylance
          ms-vscode-remote.remote-containers
          ms-vscode.cmake-tools
          ms-vscode.cpptools
          pkief.material-icon-theme
          redhat.vscode-yaml
          ritwickdey.liveserver
          rust-lang.rust-analyzer
          tamasfe.even-better-toml
          vadimcn.vscode-lldb
          wakatime.vscode-wakatime
          # keep-sorted end
        ])
        ++ (with pkgs.unstablePkgs.vscode-extensions; [
          # keep-sorted start
          anthropic.claude-code # follows the claude-code version
          ms-python.vscode-python-envs # stable bundles the windows arm64 `pet.exe` instead of the linux `pet`
          # keep-sorted end
        ]);

      userSettings = {
        "editor.wordWrap" = "on";

        "editor.formatOnSave" = true;
        "files.autoSave" = "onFocusChange"; # not `afterDelay`: vscode skips format on save for those saves

        "git.confirmSync" = false; # disable the boring confirmation dialog on every push
        "git.openRepositoryInParentFolders" = "never"; # never open a repository in parent folders of workspaces or open files

        "terminal.integrated.stickyScroll.enabled" = false; # disable the weird-looking and obstructive block in the terminal header
        "terminal.integrated.env.linux".EDITOR = "${lib.getExe config.programs.vscode.package} --wait";

        "window.zoomLevel" = -1; # set default zoom level to 80% (actually 83%)

        "workbench.startupEditor" = "none"; # don't show the welcome page on startup
        "workbench.iconTheme" = "material-icon-theme";

        "security.workspace.trust.enabled" = false; # disable workspace trust prompts

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings".nil = {
          formatting.command = ["treefmt" "--stdin" "stdin.nix"]; # format with the devenv's `treefmt`; nil pipes only the content, and treefmt picks formatters by the `--stdin` path

          nix.flake.autoArchive = true; # fetch missing flake inputs without asking
        };

        # run home-manager's `claude` with its plugins instead of the bundled binary
        "claudeCode.claudeProcessWrapper" = pkgs.writeShellScript "claude-vscode-wrapper" ''
          shift # drop the bundled binary's path, which the extension passes first

          exec ${lib.getExe config.programs.claude-code.finalPackage} "$@"
        '';

        "claudeCode.preferredLocation" = "panel"; # keep explicit because the extension writes it on every open in a panel, and vscode only skips the write into this read-only file when the value is already there

        # the hosts run podman instead of docker
        "dev.containers.dockerPath" = "podman";
        "dev.containers.dockerComposePath" = lib.getExe pkgs.podman-compose;

        "C_Cpp.clang_format_fallbackStyle" = "none"; # leave code without a `.clang-format` as is instead of reformatting it into the visual studio style

        "extensions.ignoreRecommendations" = true; # extensions come only from nix, so their install buttons can't work

        "update.showReleaseNotes" = false;

        "telemetry.telemetryLevel" = "off";
      };
    };
  };

  home.sessionVariables.EDITOR = "${lib.getExe config.programs.vscode.package} --wait";

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/json" = "code.desktop";
    "application/sql" = "code.desktop";
    "application/toml" = "code.desktop";
    "application/x-docbook+xml" = "code.desktop";
    "application/x-perl" = "code.desktop";
    "application/x-php" = "code.desktop";
    "application/x-ruby" = "code.desktop";
    "application/x-shellscript" = "code.desktop";
    "application/x-yaml" = "code.desktop";
    "application/xml" = "code.desktop"; # also takes `*.ts` and `*.tsx` from browsers: shared-mime-info detects them as xml subtypes (lol)
    "application/yaml" = "code.desktop";
    "text/css" = "code.desktop";
    "text/csv" = "code.desktop";
    "text/javascript" = "code.desktop";
    "text/markdown" = "code.desktop";
    "text/plain" = "code.desktop";
    "text/tab-separated-values" = "code.desktop";
    "text/x-c++hdr" = "code.desktop";
    "text/x-c++src" = "code.desktop";
    "text/x-chdr" = "code.desktop";
    "text/x-cmake" = "code.desktop";
    "text/x-csrc" = "code.desktop";
    "text/x-java" = "code.desktop";
    "text/x-log" = "code.desktop";
    "text/x-makefile" = "code.desktop";
    "text/x-meson" = "code.desktop";
    "text/x-patch" = "code.desktop";
    "text/x-python" = "code.desktop";
    "text/x-readme" = "code.desktop";
    # keep-sorted end
  };
}
