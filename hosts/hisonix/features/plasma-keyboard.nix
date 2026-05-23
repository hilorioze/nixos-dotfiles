{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.kdePackages.plasma-keyboard # provide onscreen keyboard
  ];
}
