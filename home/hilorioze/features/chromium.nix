{pkgs, ...}: {
  programs.chromium = {
    enable = true;

    package = pkgs.ungoogled-chromium;

    extensions = [
      # keep-sorted start by_regex=#\s(.+)
      {id = "mmlmfjhmonkocbjadbfplnigmagldckm";} # Playwright Extension
      {id = "okdfcljlaacbdacenfeaiekllplonlfm";} # Synclify
      {id = "ddkjiahejlhfcafbddmgiahcphecmpfh";} # uBlock Origin Lite
      # keep-sorted end
    ];
  };
}
