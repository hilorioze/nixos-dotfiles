_final: prev: {
  switch-to-configuration-ng = prev.switch-to-configuration-ng.overrideAttrs (oldAttrs: {
    # user units restarted before `suid-sgid-wrappers.service` start through the previous generation's `/run/wrappers`, e.g. gamemoded then runs the old build and asks for a password on every pkexec, as the polkit rules only allow the new one
    patches =
      (oldAttrs.patches or [])
      ++ [./user-units-after-wrappers.patch];
  });
}
