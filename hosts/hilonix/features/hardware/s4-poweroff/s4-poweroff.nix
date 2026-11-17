{pkgs, ...}: {
  # opening `/dev/snapshot` runs nvidia's suspend notifier, which saves video memory into an `O_TMPFILE` under `TemporaryFilePath`, by default `/tmp`; `/tmp` is on the root, which is read-only by the time shutdown hooks run, so the save fails and unloading the gpu crashes the gsp; save it to `/dev/shm`, which systemd keeps mounted
  hardware.nvidia.moduleParams.nvidia.NVreg_TemporaryFilePath = "/dev/shm";

  # power off into acpi S4 through the kernel's hibernation path to power on by a key press: the dsdt allows usb wake only from S4
  systemd.shutdown.s4-poweroff = pkgs.writers.writePython3 "s4-poweroff" {
    doCheck = false; # treefmt lints the script with ruff
  } (builtins.readFile ./s4-poweroff.py);
}
