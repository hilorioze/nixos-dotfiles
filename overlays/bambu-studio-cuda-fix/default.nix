final: prev: {
  bambu-studio = prev.bambu-studio.overrideAttrs (oldAttrs: {
    # expose nix's split cuda toolkit to opencv's cmake config
    nativeBuildInputs =
      oldAttrs.nativeBuildInputs
      ++ final.lib.optionals final.config.cudaSupport [final.cudaPackages.cuda_nvcc];

    cmakeFlags =
      oldAttrs.cmakeFlags
      ++ final.lib.optionals final.config.cudaSupport [
        "-DCUDAToolkit_ROOT=${final.cudaPackages.cudatoolkit}"
        "-DCUDA_CUDART=${final.cudaPackages.cudatoolkit}/lib/libcudart.so"
      ];
  });
}
