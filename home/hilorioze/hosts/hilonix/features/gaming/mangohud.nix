{lib, ...}: {
  # mangohud starts nvml in every vulkan app, whichever gpu it renders on, and holds `/dev/nvidia*`, which blocks passing the gpu to the w10 vm; steam games still get it from their launch shell
  programs.mangohud.enableSessionWide = lib.mkForce false;
}
