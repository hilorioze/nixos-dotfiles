{
  # keep-sorted start
  config,
  pkgs,
  # keep-sorted end
  ...
}: {
  programs.librewolf.package = pkgs.librewolf.overrideAttrs (oldAttrs: {
    makeWrapperArgs =
      (oldAttrs.makeWrapperArgs or [])
      ++ [
        "--set"
        "MOZ_DRM_DEVICE"
        "/dev/dri/by-path/pci-0000:0c:00.0-render"

        "--set"
        "__EGL_VENDOR_LIBRARY_FILENAMES"
        "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
      ];
  });

  sops = {
    secrets."apps/keepassxc/key" = {};

    templates."apps/keepassxc/storage-keyring.json".content = let
      databaseHash = "fb9a50b4543f9ff95e065ab937916c5e73980e49282a82fab075608bfb382e89";
    in
      builtins.toJSON {
        keyRing."${databaseHash}" = {
          id = "librewolf-hilonix";

          hash = databaseHash;

          key = config.sops.placeholder."apps/keepassxc/key";
        };
      };
  };
}
