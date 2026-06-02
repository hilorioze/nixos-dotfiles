{
  # keep-sorted start
  config,
  lib,
  pkgs,
  # keep-sorted end
  ...
}: {
  imports = [../../common/features/librewolf.nix];

  sops = {
    secrets."apps/dearrow/license-key" = {};

    templates."apps/keepassxc/storage.js" = {
      content = builtins.toJSON (lib.recursiveUpdate (builtins.fromJSON config.sops.templates."apps/keepassxc/storage-keyring.json".content) {
        settings = {
          autoFillAndSend = true;

          passkeys = true;
        };
      });

      path = "${config.home.homeDirectory}/.librewolf/default/browser-extension-data/keepassxc-browser@keepassxc.org/storage.js";
    };
  };

  stylix.targets.librewolf = {
    colorTheme.enable = true;

    profileNames = ["default"];
  };

  programs.librewolf = {
    nativeMessagingHosts = with pkgs; [
      # keep-sorted start
      kdePackages.plasma-browser-integration
      keepassxc
      # keep-sorted end
    ];

    profiles.default = {
      search = {
        force = true;
        default = "ddg";
        privateDefault = "ddg";
        order = [
          # keep-sorted start
          "ddg"
          "google"
          # keep-sorted end
        ];
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

        # always underline links
        "layout.css.always_underline_links" = true;

        # disable quick action entries shown in the urlbar suggestion dropdown
        "browser.urlbar.suggest.quickactions" = false;

        # enable search suggestions
        "browser.search.suggest.enabled" = true;
        "browser.urlbar.suggest.searches" = true;

        # disable tabs in titlebar
        "browser.tabs.inTitlebar" = 0;

        # enable webgl (disabled by default in librewolf)
        "webgl.disabled" = false;

        # disable fingerprinting resistance (enabled by default in librewolf); at least breaks dark themes on sites for me
        "privacy.resistFingerprinting" = false;

        # keep browsing data between sessions (by default librewolf clears it on shutdown)
        "privacy.sanitize.sanitizeOnShutdown" = false;

        "browser.urlbar.trimURLs" = false;
        "browser.sessionstore.resume_from_crash" = false;
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
    if [[ -f "${config.home.homeDirectory}/.librewolf/default/storage-sync-v2.sqlite" ]]; then
      ${lib.getExe pkgs.sqlite} "${config.home.homeDirectory}/.librewolf/default/storage-sync-v2.sqlite" \
        "INSERT OR IGNORE INTO storage_sync_data (ext_id, data) VALUES ('deArrow@ajay.app', '{}');" \
        "UPDATE storage_sync_data SET data = json_set(data, '$.licenseKey', '$(${lib.getExe' pkgs.coreutils "cat"} ${config.sops.secrets."apps/dearrow/license-key".path})', '$.activated', json('true'), '$.alreadyActivated', json('true')) WHERE ext_id = 'deArrow@ajay.app';"
    fi
  '';

  xdg.mimeApps.defaultApplications = {
    # keep-sorted start
    "application/x-extension-htm" = "librewolf.desktop";
    "application/x-extension-html" = "librewolf.desktop";
    "application/x-extension-shtml" = "librewolf.desktop";
    "application/x-extension-xht" = "librewolf.desktop";
    "application/x-extension-xhtml" = "librewolf.desktop";
    "application/xhtml+xml" = "librewolf.desktop";
    "text/html" = "librewolf.desktop";
    "text/xml" = "librewolf.desktop";
    "x-scheme-handler/about" = "librewolf.desktop";
    "x-scheme-handler/chrome" = "librewolf.desktop";
    "x-scheme-handler/ftp" = "librewolf.desktop";
    "x-scheme-handler/http" = "librewolf.desktop";
    "x-scheme-handler/https" = "librewolf.desktop";
    "x-scheme-handler/unknown" = "librewolf.desktop";
    # keep-sorted end
  };
}
