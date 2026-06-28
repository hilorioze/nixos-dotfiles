{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.vscodium = {
    enable = true;

    mutableExtensionsDir = false;

    profiles.default = {
      enableUpdateCheck = false;

      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        # keep-sorted start
        eamodio.gitlens
        editorconfig.editorconfig
        github.codespaces
        github.vscode-github-actions
        jnoortheen.nix-ide
        kilocode.kilo-code
        mkhl.direnv
        ms-python.debugpy
        ms-python.python
        ms-python.vscode-pylance
        ms-vscode.cmake-tools
        ms-vscode.cpptools
        pkief.material-icon-theme
        ritwickdey.liveserver
        rust-lang.rust-analyzer
        wakatime.vscode-wakatime
        # keep-sorted end
      ];

      userSettings = {
        "editor.wordWrap" = "on";

        "files.autoSave" = "afterDelay";

        "git.autofetch" = true;
        "git.confirmSync" = false; # disable the boring confirmation dialog on every push
        "git.openRepositoryInParentFolders" = "never"; # never open a repository in parent folders of workspaces or open files

        "terminal.integrated.stickyScroll.enabled" = false; # disable the weird-looking and obstructive block in the terminal header
        "terminal.integrated.env.linux".EDITOR = "${lib.getExe config.programs.vscodium.package} --wait";
        "terminal.integrated.commandsToSkipShell" = [
          # required by kilocode to be set
          "kilo-code.new.agentManagerOpen"
          "kilo-code.new.agentManager.showTerminal"
        ];

        "window.zoomLevel" = -1; # set default zoom level to 80%

        "workbench.startupEditor" = "none"; # don't show the welcome page on startup
        "workbench.iconTheme" = "material-icon-theme";

        "security.workspace.trust.enabled" = false; # disable workspace trust prompts

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${lib.getExe pkgs.nil}";
        "nix.serverSettings".nil.formatting.command = ["${lib.getExe pkgs.alejandra}"];

        # required by kilocode to be set
        "kilo-code.new.agentWorkStyle" = "skipped";

        "update.showReleaseNotes" = false;
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/json" = "codium.desktop";
    "application/sql" = "codium.desktop";
    "application/toml" = "codium.desktop";
    "application/x-docbook+xml" = "codium.desktop";
    "application/x-perl" = "codium.desktop";
    "application/x-php" = "codium.desktop";
    "application/x-ruby" = "codium.desktop";
    "application/x-shellscript" = "codium.desktop";
    "application/x-yaml" = "codium.desktop";
    "application/yaml" = "codium.desktop";
    "text/css" = "codium.desktop";
    "text/csv" = "codium.desktop";
    "text/javascript" = "codium.desktop";
    "text/markdown" = "codium.desktop";
    "text/plain" = "codium.desktop";
    "text/tab-separated-values" = "codium.desktop";
    "text/x-c++hdr" = "codium.desktop";
    "text/x-c++src" = "codium.desktop";
    "text/x-chdr" = "codium.desktop";
    "text/x-cmake" = "codium.desktop";
    "text/x-csrc" = "codium.desktop";
    "text/x-java" = "codium.desktop";
    "text/x-log" = "codium.desktop";
    "text/x-makefile" = "codium.desktop";
    "text/x-meson" = "codium.desktop";
    "text/x-patch" = "codium.desktop";
    "text/x-python" = "codium.desktop";
    "text/x-readme" = "codium.desktop";
    # keep-sorted end
  };
}
