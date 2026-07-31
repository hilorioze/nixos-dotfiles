{inputs, ...}: {
  imports = [inputs.lazyvim-nix.homeManagerModules.default];

  programs.lazyvim = {
    enable = true;

    config.options = ''
      vim.opt.wrap = true
    '';

    plugins = let
      mkPlugin = inputs.lazyvim-nix.lib.lazyConfig;
    in {
      # keep-sorted start block=yes newline_separated=yes
      autosave = mkPlugin {
        plugin = "okuuva/auto-save.nvim";

        opts = {};
      };

      conform = mkPlugin {
        plugin = "stevearc/conform.nvim";

        opts = {
          # use `devenv`'s generated wrapper instead of looking for `treefmt.toml`
          formatters.treefmt.require_cwd = false;

          formatters_by_ft.nix = ["treefmt"];
        };
      };

      snacks = mkPlugin {
        plugin = "folke/snacks.nvim";

        opts.picker.sources = {
          explorer.hidden = true;
          files.hidden = true;
          grep.hidden = true;
        };
      };
      # keep-sorted end
    };

    extras.lang.nix.enable = true;
  };
}
