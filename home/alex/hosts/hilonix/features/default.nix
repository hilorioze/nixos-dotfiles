{inputs, ...}: {
  imports = [
    # keep-sorted start
    ../../../../common/features/desktop/fonts/corefonts.nix
    ../../../../common/features/desktop/fonts/meslo-nerd-font.nix
    ../../../../common/features/desktop/fonts/vista-fonts.nix
    ../../../../common/features/desktop/plasma/baloo.nix
    ../../../../common/features/desktop/plasma/kactivitymanagerd.nix
    ../../../../common/features/desktop/plasma/kdialog.nix
    ../../../../common/features/desktop/plasma/plasma.nix
    ../../../../common/features/files/7z.nix
    ../../../../common/features/files/ark.nix
    ../../../../common/features/files/dolphin.nix
    ../../../../common/features/files/rar.nix
    ../../../../common/features/gaming/mangohud.nix
    ../../../../common/features/hardware/thermalmonitor.nix
    ../../../../common/features/media/haruna.nix
    ../../../../common/features/media/spectacle.nix
    ../../../../common/features/network/kdeconnect.nix
    ../../../../common/features/network/trayscale.nix
    ../../../../common/features/productivity/kcalc.nix
    ../../../../common/features/productivity/onlyoffice.nix
    ../../../../common/features/security/keepassxc.nix
    ../../../../common/features/terminal/konsole.nix
    # keep-sorted end

    # keep-sorted start
    ../../../features/browsers/google-chrome.nix
    ../../../features/communication/telegram-desktop.nix
    ../../../features/desktop/stylix.nix
    # keep-sorted end

    (inputs.import-tree.filterNot (path: path == "/default.nix") ./.) # this file is left out so it doesn't import itself
  ];
}
