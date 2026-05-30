{lib, ...}: {
  systemd.services = {
    prepare-kexec = {
      before = lib.mkAfter ["systemd-reboot.service"];
      wantedBy = lib.mkAfter ["reboot.target"];
    };

    systemd-reboot.unitConfig = {
      SuccessAction = "kexec-force";
      FailureAction = "reboot-force";
    };
  };
}
