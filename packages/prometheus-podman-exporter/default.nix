{
  # keep-sorted start
  btrfs-progs,
  buildGoModule,
  fetchFromGitHub,
  gpgme,
  lib,
  pkg-config,
  # keep-sorted end
  ...
}:
buildGoModule (finalAttrs: {
  pname = "prometheus-podman-exporter";

  version = "1.21.1";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "prometheus-podman-exporter";

    tag = "v${finalAttrs.version}";
    hash = "sha256-SJXUi5bG8sPew5fHI3N2TWwnozUIm3W2asyIEOrgXBE=";
  };

  vendorHash = null;

  strictDeps = true;

  nativeBuildInputs = [pkg-config];

  buildInputs = [
    # keep-sorted start
    btrfs-progs
    gpgme
    # keep-sorted end
  ];

  # upstream integration tests need a live podman runtime, which does not work in the nix sandbox
  doCheck = false;

  meta = {
    description = "Prometheus exporter for podman environments exposing containers, pods, images, volumes and networks information";
    homepage = "https://github.com/containers/prometheus-podman-exporter";

    license = lib.licenses.asl20;

    mainProgram = "prometheus-podman-exporter";

    platforms = ["aarch64-linux"];
  };
})
