{
  # keep-sorted start
  inputs,
  lib,
  # keep-sorted end
  ...
}: {
  imports = [inputs.lazyvim-nix.homeManagerModules.default];

  programs.lazyvim = {
    enable = true;

    config = {
      keymaps = ''
        vim.keymap.set("i", "<C-q>", "<Esc>", { desc = "Escape" })
        vim.keymap.set("t", "<C-q>", "<C-\\><C-n>", { desc = "Escape Terminal" })
      '';

      options = ''
        vim.opt.wrap = true -- soft word wrap
      '';
    };

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

      # `editor.outline` loads before `ui.edgy` due to alphabetical ordering in `lazyvim-nix`,
      # causing `ui.edgy`'s fresh `opts` to drop the `Outline` panel; re-add it in
      # `programs.lazyvim.plugins`, which `lazyvim-nix` always appends after extras
      edgy = mkPlugin {
        plugin = "folke/edgy.nvim";

        optional = true;

        opts = lib.generators.mkLuaInline ''
          function(_, opts)
            opts.right = opts.right or {}

            table.insert(opts.right, {
              title = "Outline",
              ft = "Outline",

              pinned = true,
              open = "Outline",
            })
          end
        '';
      };

      lspconfig = mkPlugin {
        plugin = "neovim/nvim-lspconfig";

        opts_extend = ["servers.clangd.cmd"];

        opts.servers = {
          clangd.cmd = ["--query-driver=**/clangd-i686-gcc"];

          nil_ls.settings.nil.nix.flake.autoArchive = true;
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

    extras = {
      # keep-sorted start block=yes newline_separated=yes
      coding = {
        # keep-sorted start
        mini-surround.enable = true;
        yanky.enable = true;
        # keep-sorted end
      };

      dap.core.enable = true;

      editor = {
        # keep-sorted start
        dial.enable = true;
        harpoon2.enable = true;
        inc-rename.enable = true;
        leap.enable = true;
        outline.enable = true;
        overseer.enable = true;
        refactoring.enable = true;
        # keep-sorted end
      };

      lang = {
        # keep-sorted start
        clangd.enable = true;
        git.enable = true;
        json.enable = true;
        markdown.enable = true;
        nix.enable = true;
        php.enable = true;
        python.enable = true;
        rust.enable = true;
        toml.enable = true;
        typescript.enable = true;
        yaml.enable = true;
        # keep-sorted end
      };

      test.core.enable = true;

      ui = {
        # keep-sorted start
        edgy.enable = true;
        smear-cursor.enable = true;
        treesitter-context.enable = true;
        # keep-sorted end
      };

      util = {
        # keep-sorted start
        mini-hipatterns.enable = true;
        octo.enable = true;
        # keep-sorted end
      };
      # keep-sorted end
    };
  };
}
