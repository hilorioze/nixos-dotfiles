lazyvimOverlay: final: prev: {
  # fix lazyvim-nix resolving `wakatime/vim-wakatime` to nonexistent `vim_wakatime` instead of `vim-wakatime` due to `resolvePluginName` normalizing `-` to `_`
  lazyvimPluginMappings =
    (lazyvimOverlay final prev).lazyvimPluginMappings
    // {
      "wakatime/vim-wakatime" = "vim-wakatime";
    };
}
