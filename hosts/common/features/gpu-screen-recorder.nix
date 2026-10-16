{
  # keep-sorted start
  config,
  inputs,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  disabledModules = ["programs/gpu-screen-recorder.nix"];

  imports = ["${inputs.nixpkgs-unstable}/nixos/modules/programs/gpu-screen-recorder.nix"]; # `ui` options are not in 26.05

  environment.systemPackages = [
    (pkgs.makeAutostartItem {
      name = "gpu-screen-recorder";

      package = config.programs.gpu-screen-recorder.ui.package;
    })
  ];

  programs.gpu-screen-recorder = {
    enable = true;

    package = pkgs.unstablePkgs.gpu-screen-recorder;

    ui = {
      enable = true;

      package = lib.mkDefault pkgs.unstablePkgs.gpu-screen-recorder-ui;
      notifPackage = pkgs.unstablePkgs.gpu-screen-recorder-notification;
    };
  };
}
