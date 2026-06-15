{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: let
  firefoxProfileDir = "${config.home.homeDirectory}/${config.programs.firefox.configPath}/${config.programs.firefox.profiles.default.path}";
in {
  imports = [../../common/features/firefox.nix];

  sops = {
    secrets."apps/dearrow/license-key" = {};

    templates."apps/keepassxc/storage.js" = {
      content = builtins.toJSON (lib.recursiveUpdate (builtins.fromJSON config.sops.templates."apps/keepassxc/storage-keyring.json".content) {
        settings = {
          autoFillAndSend = true;

          passkeys = true;
        };
      });

      path = "${firefoxProfileDir}/browser-extension-data/keepassxc-browser@keepassxc.org/storage.js";
    };
  };

  stylix.targets.firefox = {
    colorTheme.enable = true;

    profileNames = ["default"];
  };

  programs.firefox = {
    nativeMessagingHosts = with pkgs; [
      # keep-sorted start
      kdePackages.plasma-browser-integration
      keepassxc
      # keep-sorted end
    ];

    profiles.default = {
      search = let
        defaultEngine = "ddg";
      in {
        default = defaultEngine;
        privateDefault = defaultEngine;

        order = [
          defaultEngine

          "google"
        ];

        force = true;
      };

      extensions = {
        force = true; # required when using `settings`

        packages = with pkgs.firefox-addons; [
          # keep-sorted start
          clearurls
          darkreader
          dearrow
          keepa
          keepassxc-browser
          plasma-integration
          re-enable-right-click
          return-youtube-dislikes
          ruffle_rs
          search-by-image # search_by_image
          sponsorblock
          steam-database
          translate-web-pages # traduzir-paginas-web
          ublock-origin
          user-agent-string-switcher
          video-downloadhelper
          violentmonkey
          web-archives # view-page-archive
          # keep-sorted end
        ];

        settings."uBlock0@raymondhill.net".settings = {
          # https://github.com/gorhill/uBlock/blob/d2c3d9a33edaa5897b5c4bce79c2d156e8459872/assets/assets.json
          selectedFilterLists = [
            # keep-sorted start
            "adguard-spyware-url"
            "easylist"
            "easyprivacy"
            "fanboy-cookiemonster"
            "ublock-badware"
            "ublock-cookies-easylist"
            "ublock-filters"
            "ublock-privacy"
            "ublock-quick-fixes"
            "ublock-unbreak"
            # keep-sorted end
          ];

          netWhitelist = ["duckduckgo.com"];
        };
      };

      settings = {
        "middlemouse.paste" = false;

        # enable middle-click autoscroll
        "general.autoScroll" = true;

        "layout.css.always_underline_links" = true;

        # disable quick action entries shown in the urlbar suggestion dropdown
        "browser.urlbar.suggest.quickactions" = false;

        # disable tabs in titlebar
        "browser.tabs.inTitlebar" = 0;

        "browser.urlbar.trimURLs" = false;

        "browser.tabs.closeWindowWithLastTab" = false;

        "findbar.highlightAll" = true;
      };
    };

    policies.ExtensionSettings = {
      # keep-sorted start
      "keepassxc-browser@keepassxc.org".private_browsing = true;
      "uBlock0@raymondhill.net".private_browsing = true;
      # keep-sorted end
    };
  };

  home.activation.setDeArrowLicense = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -f "${firefoxProfileDir}/storage-sync-v2.sqlite" ]]; then
      ${lib.getExe pkgs.sqlite} "${firefoxProfileDir}/storage-sync-v2.sqlite" \
        "INSERT OR IGNORE INTO storage_sync_data (ext_id, data) VALUES ('deArrow@ajay.app', '{}');" \
        "UPDATE storage_sync_data SET data = json_set(data, '$.licenseKey', '$(${lib.getExe' pkgs.coreutils "cat"} ${config.sops.secrets."apps/dearrow/license-key".path})', '$.activated', json('true'), '$.alreadyActivated', json('true')) WHERE ext_id = 'deArrow@ajay.app';"
    fi
  '';

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/x-extension-htm" = "firefox.desktop";
    "application/x-extension-html" = "firefox.desktop";
    "application/x-extension-shtml" = "firefox.desktop";
    "application/x-extension-xht" = "firefox.desktop";
    "application/x-extension-xhtml" = "firefox.desktop";
    "application/xhtml+xml" = "firefox.desktop";
    "text/html" = "firefox.desktop";
    "text/xml" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/chrome" = "firefox.desktop";
    "x-scheme-handler/ftp" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
    # keep-sorted end
  };
}
