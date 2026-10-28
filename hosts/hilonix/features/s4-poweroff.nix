{pkgs, ...}: {
  # opening `/dev/snapshot` runs nvidia's suspend notifier, which saves video memory into an `O_TMPFILE` under `TemporaryFilePath`, by default `/tmp`; `/tmp` is on the root, which is read-only by the time shutdown hooks run, so the save fails and unloading the gpu crashes the gsp; save it to `/dev/shm`, which systemd keeps mounted
  hardware.nvidia.moduleParams.nvidia.NVreg_TemporaryFilePath = "/dev/shm";

  # power off into acpi S4 through the kernel's hibernation path to power on by a key press: the dsdt allows usb wake only from S4
  systemd.shutdown.s4-poweroff =
    pkgs.writers.writePython3 "s4-poweroff" {
      flakeIgnore = (import ../../../shared.nix).ignoredFlake8Rules;
    }
    # python
    ''
      import fcntl
      import sys


      # https://github.com/torvalds/linux/blob/8d3ae59288f1e7d58d76558a6ee96d533bc5019f/include/uapi/asm-generic/ioctl.h#L69-L85
      def _io(type_: int, nr: int) -> int:
          return type_ << 8 | nr


      # https://github.com/torvalds/linux/blob/8d3ae59288f1e7d58d76558a6ee96d533bc5019f/include/uapi/linux/suspend_ioctls.h#L16-L27
      SNAPSHOT_IOC_MAGIC: int = ord("3")

      SNAPSHOT_FREEZE: int = _io(SNAPSHOT_IOC_MAGIC, 1)
      SNAPSHOT_PLATFORM_SUPPORT: int = _io(SNAPSHOT_IOC_MAGIC, 15)
      SNAPSHOT_POWER_OFF: int = _io(SNAPSHOT_IOC_MAGIC, 16)


      def main() -> None:
          verb: str = sys.argv[1]

          if verb != "poweroff":
              return

          with open("/dev/snapshot", "rb") as snapshot:
              # sync filesystems and freeze processes before suspending devices, as the kernel's own hibernation does
              fcntl.ioctl(snapshot, SNAPSHOT_FREEZE)

              # make `SNAPSHOT_POWER_OFF` go through acpi instead of doing nothing
              fcntl.ioctl(snapshot, SNAPSHOT_PLATFORM_SUPPORT, 1)

              # suspend devices and enter acpi S4
              fcntl.ioctl(snapshot, SNAPSHOT_POWER_OFF)


      if __name__ == "__main__":
          main()
    '';
}
