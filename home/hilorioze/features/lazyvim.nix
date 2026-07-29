{inputs, ...}: {
  imports = [inputs.lazyvim-nix.homeManagerModules.default];

  programs.lazyvim = {
    enable = true;

    plugins.conform = inputs.lazyvim-nix.lib.lazyConfig {
      plugin = "stevearc/conform.nvim";

      opts.formatters_by_ft.nix = ["alejandra"];
    };

    extras.lang.nix.enable = true;
  };
}
