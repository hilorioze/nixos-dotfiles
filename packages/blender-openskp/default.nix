{
  # keep-sorted start
  fetchurl,
  lib,
  openskp,
  stdenvNoCC,
  unzip,
  # keep-sorted end
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "blender-openskp";

  version = "0.2.6";

  src = fetchurl {
    url = "https://github.com/iamahsanmehmood/blender-openskp/releases/download/v${finalAttrs.version}/blender-openskp-v${finalAttrs.version}.zip";

    hash = "sha256-3K9gy9ozpPAK99lpFf73XvLnAFuKwPgq5cjZZx2Ke5s=";
  };

  dontUnpack = true;

  strictDeps = true;

  nativeBuildInputs = [unzip];

  propagatedBuildInputs = [openskp];

  installPhase = ''
    runHook preInstall

    extension=$out/share/blender/extensions/system/openskp_import_export
    mkdir --parents $extension
    unzip $src __init__.py import_skp.py export_skp.py LICENSE -d $extension

    # python dependencies come from nix, not blender's wheel installer
    unzip -p $src blender_manifest.toml | sed '/^wheels = \[/,/^]/d' >$extension/blender_manifest.toml

    runHook postInstall
  '';

  meta = {
    description = "Blender add-on for importing and exporting SketchUp (.skp) files";
    homepage = "https://github.com/iamahsanmehmood/blender-openskp";

    license = lib.licenses.gpl3Plus;

    platforms = ["x86_64-linux"];
  };
})
