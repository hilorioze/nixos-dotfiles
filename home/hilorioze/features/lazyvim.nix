{
  # keep-sorted start
  inputs,
  lib,
  osConfig,
  pkgs,
  # keep-sorted end
  ...
}: {
  # lazyvim-nix bumped nvim-treesitter to `5cb0114` without regenerating `data/parser-manifest.json`, so parsers stay at `539abf6` revisions and newer queries fail on old grammars, e.g. `(change)` in diff
  imports = let
    lazyvim-nix = inputs.nixpkgs.legacyPackages.${osConfig.nixpkgs.hostPlatform.system}.applyPatches {
      name = "lazyvim-nix";
      src = inputs.lazyvim-nix;

      patches = [./lazyvim-nix-parser-manifest.patch];
    };
  in ["${lazyvim-nix}/nix/module.nix"];

  programs.lazyvim = {
    enable = true;

    extraPackages = with pkgs; [
      # keep-sorted start
      markdownlint-cli2 # required by `extras.lang.markdown`
      nil # required by `extras.lang.nix` outside devenv; neovim appends these packages to the inherited `PATH`, so a devenv's own nil comes first
      vscode-json-languageserver # required by `extras.lang.json`
      yaml-language-server # required by `extras.lang.yaml`
      # keep-sorted end
    ];

    config = {
      keymaps = ''
        vim.keymap.set("i", "<C-q>", "<Esc>", { desc = "Escape" })
        vim.keymap.set("t", "<C-q>", "<C-\\><C-n>", { desc = "Escape Terminal" })
      '';

      options = ''
        vim.env.EDITOR = "${lib.getExe pkgs.neovim-remote} -l --remote-wait"

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

      claudecode = mkPlugin {
        plugin = "coder/claudecode.nvim";

        lazy = false; # start the ide integration server with neovim, so claude running elsewhere can connect to it
      };

      conform = mkPlugin {
        plugin = "stevearc/conform.nvim";

        opts = {
          # use devenv's generated wrapper instead of looking for `treefmt.toml`
          formatters.treefmt.require_cwd = false;

          formatters_by_ft.nix = ["treefmt"];
        };
      };

      # `editor.outline` loads before `ui.edgy` due to alphabetical ordering in lazyvim-nix,
      # causing `ui.edgy`'s fresh `opts` to drop the `Outline` panel; re-add it in
      # `programs.lazyvim.plugins`, which lazyvim-nix always appends after extras
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

      wakatime = mkPlugin {
        plugin = "wakatime/vim-wakatime";

        lazy = false;
      };
      # keep-sorted end
    };

    extras = {
      # keep-sorted start block=yes newline_separated=yes
      ai.claudecode.enable = true; # ide integration for claude; also adds the `<leader>a` keys that run it inside neovim

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

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/json" = "nvim.desktop";
    "application/sql" = "nvim.desktop";
    "application/toml" = "nvim.desktop";
    "application/x-docbook+xml" = "nvim.desktop";
    "application/x-perl" = "nvim.desktop";
    "application/x-php" = "nvim.desktop";
    "application/x-ruby" = "nvim.desktop";
    "application/x-shellscript" = "nvim.desktop";
    "application/x-yaml" = "nvim.desktop";
    "application/yaml" = "nvim.desktop";
    "text/css" = "nvim.desktop";
    "text/csv" = "nvim.desktop";
    "text/javascript" = "nvim.desktop";
    "text/markdown" = "nvim.desktop";
    "text/plain" = "nvim.desktop";
    "text/tab-separated-values" = "nvim.desktop";
    "text/x-c++hdr" = "nvim.desktop";
    "text/x-c++src" = "nvim.desktop";
    "text/x-chdr" = "nvim.desktop";
    "text/x-cmake" = "nvim.desktop";
    "text/x-csrc" = "nvim.desktop";
    "text/x-java" = "nvim.desktop";
    "text/x-log" = "nvim.desktop";
    "text/x-makefile" = "nvim.desktop";
    "text/x-meson" = "nvim.desktop";
    "text/x-patch" = "nvim.desktop";
    "text/x-python" = "nvim.desktop";
    "text/x-readme" = "nvim.desktop";
    # keep-sorted end
  };
}
