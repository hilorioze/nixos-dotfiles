{pkgs, ...}: {
  home.packages = [
    pkgs.virt-manager
  ];

  dconf.settings."org/virt-manager/virt-manager/connections" = {
    uris = [
      # keep-sorted start
      "qemu:///session"
      "qemu:///system"
      # keep-sorted end
    ];

    autoconnect = [
      # keep-sorted start
      "qemu:///session"
      "qemu:///system"
      # keep-sorted end
    ];
  };
}
