final: prev: {
  ncps = prev.ncps.overrideAttrs (finalAttrs: oldAttrs: {
    version = "0.10.0-rc14";

    src = oldAttrs.src.override {
      tag = "v${finalAttrs.version}";
      hash = "sha256-kGtMV+U/xzDt2PLrvn9bCBtiYqdsueICsGou3lfLRKE=";
    };

    vendorHash = "sha256-MKhrXZjgYVKseXv6kBuK5TkCrrW2GcMQxnlT8OqoCeU=";

    ldflags = ["-X github.com/kalbasit/ncps/pkg/ncps.Version=v${finalAttrs.version}"];

    postInstall = "wrapProgram $out/bin/ncps --set XZ_BINARY_PATH ${final.lib.getExe' final.xz "xz"}";
  });
}
