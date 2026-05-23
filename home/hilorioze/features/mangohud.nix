{
  imports = [
    # keep-sorted start
    ../../common/features/mangohud.nix
    # keep-sorted end
  ];

  programs.mangohud.settings = {
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
}
