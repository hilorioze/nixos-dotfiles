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

      extensions =
        (with pkgs.vscode-extensions; [
          # keep-sorted start
          eamodio.gitlens
          editorconfig.editorconfig
          github.codespaces
          github.vscode-github-actions
          jnoortheen.nix-ide
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
        ])
        ++ [pkgs.nix-vscode-extensions.open-vsx-release.openai.chatgpt];

      userSettings = {
        "editor.wordWrap" = "on";

        "files.autoSave" = "afterDelay";

        "git.confirmSync" = false; # disable the boring confirmation dialog on every push
        "git.openRepositoryInParentFolders" = "never"; # never open a repository in parent folders of workspaces or open files

        "terminal.integrated.stickyScroll.enabled" = false; # disable the weird-looking and obstructive block in the terminal header
        "terminal.integrated.env.linux".EDITOR = "${lib.getExe config.programs.vscodium.package} --wait";

        "window.zoomLevel" = -1; # set default zoom level to 80%

        "workbench.startupEditor" = "none"; # don't show the welcome page on startup
        "workbench.iconTheme" = "material-icon-theme";

        "security.workspace.trust.enabled" = false; # disable workspace trust prompts

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = lib.getExe pkgs.nil;
        "nix.serverSettings".nil.formatting.command = [(lib.getExe pkgs.alejandra)];

        "update.showReleaseNotes" = false;
      };
    };
  };
}
