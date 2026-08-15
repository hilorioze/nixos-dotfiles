{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs = {
    # keep-sorted start block=yes newline_separated=true
    google-chrome.enable = true;

    mangohud = {
      enable = true;
      enableSessionWide = true;

      settings = {
        version = true;
        time = true;

        fps = true;
        frame_timing = true;

        cpu_stats = true;
        cpu_power = true;
        cpu_temp = true;

        ram = true;
        ram_temp = true;
        swap = true;

        gpu_stats = true;
        gpu_power = true;
        gpu_fan = true;
        gpu_temp = true;
        vram = true;
        gpu_mem_temp = true;

        exec_name = true;
        vulkan_driver = true;

        no_display = true; # hide the hud by default
        toggle_hud = "Shift_R + F12";
      };
    };
    # keep-sorted end
  };

  home = {
    packages = with pkgs; [
      # keep-sorted start
      corefonts
      haruna
      kdePackages.ark
      kdePackages.dolphin
      kdePackages.kio-zeroconf
      mousai
      onlyoffice-desktopeditors
      telegram-desktop
      vista-fonts
      yaas
      # keep-sorted end
    ];

    activation.copyFontsLocalShare = lib.hm.dag.entryAfter ["writeBoundary"] ''
      fonts_dir=${config.home.homeDirectory}/.local/share/fonts

      rm --recursive --force $fonts_dir
      mkdir --parents $fonts_dir
      cp ${pkgs.corefonts}/share/fonts/truetype/* $fonts_dir/
      cp ${pkgs.vista-fonts}/share/fonts/truetype/* $fonts_dir/
      chmod 755 $fonts_dir
      chmod 644 $fonts_dir/*
    '';
  };
}
