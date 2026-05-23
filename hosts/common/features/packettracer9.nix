{
  # keep-sorted start
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  ciscoPacketTracer9 = pkgs.ciscoPacketTracer9.override {
    requireFile = {
      # keep-sorted start
      hash,
      name,
      # keep-sorted end
      ...
    }:
      pkgs.fetchurl {
        inherit name;

        url = "https://archive.org/download/packettracer900/${name}";

        inherit hash;
      };
  };
in {
  programs.firejail.wrappedBinaries.packettracer9 = {
    executable = lib.getExe ciscoPacketTracer9;

    # we still want .desktop entry because package is not installed directly
    desktop = "${ciscoPacketTracer9}/share/applications/cisco-packet-tracer-9.desktop";

    extraArgs = [
      "--net=none" # prevent internet access to avoid required login via a cisco network academy account

      "--noprofile" # no separate profile is needed
    ];
  };
}
