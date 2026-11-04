{pkgs, ...}: {
  # installation through `environment.systemPackages` is required for polkit privilege escalation (home-manager install won't work)
  environment.systemPackages = [pkgs.kdiskmark];
}
