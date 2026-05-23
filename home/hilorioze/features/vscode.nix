{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/vscode.nix];

  programs.vscode = {
    mutableExtensionsDir = true; # https://github.com/nix-community/nixos-vscode-server/issues/82
    profiles.default = {
      extensions =
        (with pkgs.vscode-extensions; [
          # keep-sorted start
          eamodio.gitlens
          editorconfig.editorconfig
          github.codespaces
          github.copilot-chat
          github.vscode-github-actions
          jnoortheen.nix-ide
          mkhl.direnv
          ms-python.debugpy
          ms-python.python
          ms-python.vscode-pylance
          ms-vscode-remote.remote-ssh
          ms-vscode.cmake-tools
          ms-vscode.cpptools
          pkief.material-icon-theme
          ritwickdey.liveserver
          rust-lang.rust-analyzer
          wakatime.vscode-wakatime
          # keep-sorted end
        ])
        ++ [pkgs.nix-vscode-extensions.vscode-marketplace-release.sst-dev.opencode];

      userSettings = {
        "editor.wordWrap" = "on";

        "files.autoSave" = "afterDelay";

        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.enable" = {
          # keep-sorted start
          markdown = true;
          plaintext = true;
          scminput = true;
          # keep-sorted end
        };

        "git.autofetch" = true;
        "git.confirmSync" = false; # disable the boring confirmation dialog on every push
        "git.openRepositoryInParentFolders" = "never"; # never open a repository in parent folders of workspaces or open files

        "terminal.integrated.stickyScroll.enabled" = false; # disable the weird-looking and obstructive block in the terminal header
        "terminal.integrated.env.linux".EDITOR = "${lib.getExe config.programs.vscode.package} --wait";

        "window.zoomLevel" = -1; # set default zoom level to 80%

        "workbench.startupEditor" = "none"; # don't show the welcome page on startup
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.editor.enablePreview" = false; # disable annoying tab replacement when opening files

        "security.workspace.trust.enabled" = false; # disable workspace trust prompts

        "gitlens.ai.model" = "vscode";
        "gitlens.ai.vscode.model" = "copilot:gpt-4.1";

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${lib.getExe pkgs.nil}";
        "nix.serverSettings".nil.formatting.command = ["${lib.getExe pkgs.alejandra}"];
      };
    };
  };

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
