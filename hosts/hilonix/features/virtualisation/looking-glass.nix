{
  # keep-sorted start
  config,
  lib,
  # keep-sorted end
  ...
}: {
  boot = {
    extraModulePackages = [config.boot.kernelPackages.kvmfr];

    kernelModules = ["kvmfr"];

    extraModprobeConfig = ''
      options kvmfr static_size_mb=64
    '';
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660"
  '';

  virtualisation.libvirtd.qemu.verbatimConfig = lib.mkOptionDefault (lib.mkAfter ''
    cgroup_device_acl = ${builtins.toJSON [
      # keep-sorted start
      "/dev/full"
      "/dev/kvmfr0"
      "/dev/null"
      "/dev/ptmx"
      "/dev/random"
      "/dev/urandom"
      "/dev/userfaultfd"
      "/dev/zero"
      # keep-sorted end
    ]}
  '');
}
