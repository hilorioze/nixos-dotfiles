inputs: _final: prev: {
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (pyFinal: _pyPrev: {
        fastmcp = pyFinal.callPackage "${inputs.nixpkgs}/pkgs/development/python-modules/fastmcp" {};
        fastmcp-slim = pyFinal.callPackage "${inputs.nixpkgs}/pkgs/development/python-modules/fastmcp-slim" {};
      })
    ];
}
